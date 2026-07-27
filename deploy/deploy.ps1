<#
.SYNOPSIS
  Build -> push to ECR -> update the container on EC2, plus .env sync helpers.

.DESCRIPTION
  Runs from your local machine. Remote actions go over AWS SSM Run Command (not
  SSH), so nothing extra needs to be open on the instance.

  backend + frontend build+push from THIS machine to ECR, then reload on the APP
  instance (docker compose, default file).

  worker is different: this machine can't build the heavy CUDA image, so the whole
  build happens ON the GPU instance. The script SSMs in, git-syncs the backend repo
  there, `docker build`s Dockerfile.worker on the box, then (re)starts the replicas
  from worker-compose.yml in /opt/app. Nothing is pushed to ECR for the worker (its
  IAM role is pull-only, and the compose file runs the locally built image).

  Actions (pick one):
    -Target backend|frontend   build+push image, then reload it on the app instance
    -Target worker             git-sync + build + reload ON the GPU instance
    -Target both               backend + frontend (app instance)
    -Target all                backend + frontend + worker
    -PushEnv / -PullEnv              app box   .env  <-> local .env, then reload
    -PushWorkerEnv / -PullWorkerEnv  worker box /opt/app/.env <-> local worker.env, then reload

.EXAMPLE
  .\deploy.ps1 -Target backend
  .\deploy.ps1 -Target worker                                 # build+reload the DEFAULT branch on the GPU box
  .\deploy.ps1 -Target worker -Branch mvp-v1                  # deploy a different branch
  .\deploy.ps1 -Target both
  .\deploy.ps1 -Target all
  .\deploy.ps1 -PushEnv                                       # push app .env + reload
  .\deploy.ps1 -PullEnv                                       # pull app .env to local
  .\deploy.ps1 -PullWorkerEnv                                 # pull worker /opt/app/.env -> worker.env
  .\deploy.ps1 -PushWorkerEnv                                 # push worker.env -> GPU box + reload
#>
[CmdletBinding()]
param(
  [ValidateSet('backend', 'frontend', 'worker', 'both', 'all')]
  [string]$Target,

  [switch]$PushEnv,          # app box  <- local .env
  [switch]$PullEnv,          # app box  -> local .env
  [switch]$PushWorkerEnv,    # GPU worker box  <- local worker.env
  [switch]$PullWorkerEnv,    # GPU worker box  -> local worker.env

  [string]$Tag = 'latest',

  # Git branch the worker builds from, ON the server (worker target only).
  # Defaults to what's currently live; pass -Branch <name> to deploy any other branch.
  [string]$Branch = 'feat/refresh-tokens-and-invoices',

  # Full paths to the repos. Defaults are absolute; override if your checkout lives elsewhere.
  [string]$BackendPath  = 'C:\Users\Administrator\Desktop\backend',
  [string]$FrontendPath = 'C:\Users\Administrator\Desktop\frontend',

  # Local .env (the one docker-compose.yml reads). Defaults next to this script.
  [string]$LocalEnvPath = (Join-Path $PSScriptRoot '.env'),
  # Local worker env (used by -PushWorkerEnv / -PullWorkerEnv); keys differ from the app .env.
  [string]$LocalWorkerEnvPath = (Join-Path $PSScriptRoot 'worker.env'),

  [switch]$SkipRemote
)

$ErrorActionPreference = 'Stop'

# ============================ CONFIG ============================
$Region     = 'us-east-2'
$AccountId  = '376218549617'
$Registry   = "$AccountId.dkr.ecr.$Region.amazonaws.com"
$AwsProfile = 'klearnnote'

# --- backend (FastAPI) --- ($BackendPath comes from the -BackendPath parameter)
$BackendDockerfile = 'Dockerfile.api'
$BackendRepo       = 'poc-prod-api'
$BackendService    = 'api'          # service name in docker-compose.yml

# --- frontend (Next.js) --- ($FrontendPath comes from the -FrontendPath parameter)
$FrontendRepo    = 'poc-prod-frontend'
$FrontendService = 'frontend'
# Baked into the client bundle at BUILD time. Must be the public API origin.
$FrontendApiUrl  = 'https://api.klearnote.ai'

# --- worker (GPU separation stack) --- built ON the server from Dockerfile.worker
$WorkerDockerfile = 'Dockerfile.worker'
$WorkerRepo       = 'poc-prod-worker'   # image name; the box builds it locally, no ECR push
# CUDA torch wheel index baked in at BUILD time (on the box). cu128 matches the g4dn (T4)
# driver on the worker host; use cu126 if that host's driver is older. See CLAUDE.md.
$WorkerTorchIndexUrl = 'https://download.pytorch.org/whl/cu128'

# --- app server (backend + frontend live here) ---
$InstanceNameTag = 'poc-prod-app-ec2-instance'   # EC2 Name tag; used to find the instance
# NOTE: this currently lives under the ssm-agent SNAP revision dir, which is NOT stable
# (the revision number changes on snap updates and the old dir is deleted). Move it to a
# stable path like /opt/app/deploy and update this line — see the move steps.
$RemoteDeployDir = '/var/snap/amazon-ssm-agent/13349/deploy'

# --- worker server (separate GPU instance) ---
$WorkerInstanceNameTag = 'poc-prod-worker-ec2-instance'
$WorkerRemoteDeployDir = '/opt/app'            # stable path; holds worker-compose.yml + .env
$WorkerComposeFile     = 'worker-compose.yml'
# Backend checkout ON the worker box that gets built. A durable, root-owned clone lives
# here (alongside worker-compose.yml + .env), with an authenticated remote already stored
# in its .git/config - this script never handles git tokens, it just fetch/checkout/reset.
$WorkerRepoDir         = '/opt/app/backend'
# ===============================================================

function Fail($msg) { Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }
function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

function Get-InstanceId([string]$nameTag = $InstanceNameTag) {
  $iid = aws ec2 describe-instances --profile $AwsProfile --region $Region `
    --filters "Name=tag:Name,Values=$nameTag" "Name=instance-state-name,Values=running" `
    --query "Reservations[].Instances[].InstanceId" --output text
  if ($LASTEXITCODE -ne 0) { Fail "ec2 describe-instances failed" }
  $iid = ($iid -split '\s+') | Where-Object { $_ } | Select-Object -First 1
  if (-not $iid) { Fail "no running instance tagged '$nameTag' found" }
  return $iid
}

# Run a list of shell lines on the instance via SSM. Returns Status/Out/Err.
# 'set -e' makes it fail-fast; PATH is set because Run Command shells are minimal.
# $nameTag selects which instance (defaults to the app box).
function Invoke-Ssm([string[]]$commands, [string]$comment, [string]$nameTag = $InstanceNameTag) {
  $iid = Get-InstanceId $nameTag
  Write-Host "    instance: $iid"
  $full = @('set -e', 'export PATH=/usr/local/bin:/usr/bin:/bin:/snap/bin') + $commands

  $tmp = New-TemporaryFile
  $json = @{ commands = @($full) } | ConvertTo-Json -Compress
  # UTF-8 WITHOUT BOM — Set-Content -Encoding utf8 on PS 5.1 adds a BOM the AWS CLI can't parse.
  [System.IO.File]::WriteAllText($tmp.FullName, $json, (New-Object System.Text.UTF8Encoding($false)))
  $cmdId = aws ssm send-command --profile $AwsProfile --region $Region `
    --instance-ids $iid --document-name "AWS-RunShellScript" --comment $comment `
    --parameters "file://$($tmp.FullName)" --query "Command.CommandId" --output text
  Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  if ($LASTEXITCODE -ne 0 -or -not $cmdId) { Fail "ssm send-command failed" }

  do {
    Start-Sleep -Seconds 4
    $status = aws ssm get-command-invocation --profile $AwsProfile --region $Region `
      --command-id $cmdId --instance-id $iid --query "Status" --output text 2>$null
  } while ($status -in @('Pending', 'InProgress', 'Delayed', ''))

  $out = aws ssm get-command-invocation --profile $AwsProfile --region $Region `
    --command-id $cmdId --instance-id $iid --query "StandardOutputContent" --output text
  $err = aws ssm get-command-invocation --profile $AwsProfile --region $Region `
    --command-id $cmdId --instance-id $iid --query "StandardErrorContent" --output text
  return [pscustomobject]@{ Status = $status; Out = $out; Err = $err }
}

function Login-Ecr {
  Step "ECR login ($Registry)"
  $pw = aws ecr get-login-password --region $Region --profile $AwsProfile
  if ($LASTEXITCODE -ne 0) { Fail "aws ecr get-login-password failed (check profile '$AwsProfile')" }
  # Windows PowerShell 5.1 mangles the token when piped to --password-stdin
  # (pipe encoding + trailing newline), so ECR rejects the login with HTTP 400.
  # Write the exact bytes to a temp file (UTF-8, no BOM) and redirect it into
  # docker's stdin via cmd, keeping the token off the command line.
  $tmp = New-TemporaryFile
  [System.IO.File]::WriteAllText($tmp.FullName, $pw, (New-Object System.Text.UTF8Encoding($false)))
  try {
    cmd /c "docker login --username AWS --password-stdin $Registry < `"$($tmp.FullName)`""
  }
  finally {
    Remove-Item $tmp.FullName -Force -ErrorAction SilentlyContinue
  }
  if ($LASTEXITCODE -ne 0) { Fail "docker login failed" }
}

# Run docker with an argument array, tolerating captured stderr. docker/BuildKit
# stream progress to stderr; under ErrorActionPreference='Stop' that becomes a
# terminating error the moment output is redirected (PS 5.1) — e.g. in CI or any
# non-interactive run. Relax the preference locally, merge stderr into the output
# as plain strings, and gate on the real exit code.
function Invoke-Docker([string[]]$DockerArgs, [string]$FailMsg) {
  $eap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    & docker @DockerArgs 2>&1 | ForEach-Object { "$_" }
    $code = $LASTEXITCODE
  }
  finally {
    $ErrorActionPreference = $eap
  }
  if ($code -ne 0) { Fail $FailMsg }
}

function Build-Push-Backend {
  $image = "$Registry/${BackendRepo}:$Tag"
  Step "build backend -> $image"
  Invoke-Docker @('build', '--platform', 'linux/amd64', '-f', (Join-Path $BackendPath $BackendDockerfile), '-t', $image, $BackendPath) "backend build failed"
  Step "push $image"
  Invoke-Docker @('push', $image) "backend push failed"
}

function Build-Push-Frontend {
  $image = "$Registry/${FrontendRepo}:$Tag"
  Step "build frontend -> $image (NEXT_PUBLIC_API_URL=$FrontendApiUrl)"
  Invoke-Docker @('build', '--platform', 'linux/amd64', '--build-arg', "NEXT_PUBLIC_API_URL=$FrontendApiUrl", '-t', $image, $FrontendPath) "frontend build failed"
  Step "push $image"
  Invoke-Docker @('push', $image) "frontend push failed"
}

# The worker is built and run entirely ON the GPU box (this machine lacks the resources
# to build the CUDA image). Everything below runs there via one SSM invocation: git-sync
# the checkout, docker build, then compose up. Run Command shells run as root, so docker/
# git need no sudo. No ECR push/pull — compose runs the freshly built local image.
function Deploy-Worker {
  $image = "$Registry/${WorkerRepo}:$Tag"
  Step "SSM worker: git ($Branch) -> build ($WorkerTorchIndexUrl) -> compose up  [may take many minutes]"
  $cmds = @(
    # 1. sync source (clone must already exist — the script never handles git tokens)
    "if [ ! -d '$WorkerRepoDir/.git' ]; then echo 'ERROR: no git checkout at $WorkerRepoDir - clone the backend repo there once (with credentials) before deploying.' >&2; exit 1; fi",
    "cd $WorkerRepoDir",
    "git fetch --all --prune",
    "git checkout $Branch",
    "git reset --hard origin/$Branch",
    "echo 'building from:' && git log -1 --oneline",
    # 2. build the worker image on the host (GPU not needed to build; CUDA runtime is in the wheels)
    "docker build -f $WorkerDockerfile --build-arg TORCH_INDEX_URL=$WorkerTorchIndexUrl -t $image .",
    # 3. (re)start the replicas from the freshly built image. WORKER_IMAGE matches the
    #    compose default, so `up` uses the local build and never tries to pull from ECR.
    #    --force-recreate restarts all replicas (interrupts in-flight jobs; reaper requeues).
    "cd $WorkerRemoteDeployDir",
    "export WORKER_IMAGE=$image",
    "docker compose -f $WorkerComposeFile up -d --force-recreate",
    "docker compose -f $WorkerComposeFile ps",
    # 4. reclaim disk from the previous image layers (no ECR lifecycle applies on-box)
    "docker image prune -f"
  )
  $r = Invoke-Ssm $cmds "deploy worker" $WorkerInstanceNameTag
  if ($r.Out) { Write-Host $r.Out }
  if ($r.Status -ne 'Success') { if ($r.Err) { Write-Host $r.Err -ForegroundColor Red }; Fail "worker deploy status: $($r.Status)" }
  Write-Host "`nremote worker deploy: SUCCESS" -ForegroundColor Green
}

function Update-Remote([string[]]$services) {
  $svcList = $services -join ' '
  Step "SSM: update container(s) [$svcList]"
  $cmds = @(
    "cd $RemoteDeployDir",
    "aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $Registry",
    "docker compose pull $svcList",
    # --force-recreate: with a mutable :latest tag, `up -d` can leave the old
    # container running even after `pull` fetches a new image. Force the swap so
    # a deploy always ends on the freshly pulled image.
    "docker compose up -d --force-recreate $svcList",
    'docker compose ps'
  )
  $r = Invoke-Ssm $cmds "deploy $svcList"
  if ($r.Out) { Write-Host $r.Out }
  if ($r.Status -ne 'Success') { if ($r.Err) { Write-Host $r.Err -ForegroundColor Red }; Fail "remote update status: $($r.Status)" }
  Write-Host "`nremote update: SUCCESS" -ForegroundColor Green
}

# Push a local env file to $remoteDir/.env on $nameTag, back up the remote copy, then run
# $reloadCmd to pick it up. App and worker share this; only the paths/instance/reload differ.
function Push-Env([string]$localPath, [string]$remoteDir, [string]$nameTag, [string]$reloadCmd) {
  if (-not (Test-Path $localPath)) { Fail "local env not found: $localPath" }
  Step "push env  $localPath  ->  ${nameTag}:$remoteDir/.env  (+ reload)"
  Write-Host "    WARNING: .env contents pass through SSM command parameters, retained in SSM" -ForegroundColor Yellow
  Write-Host "    command history / CloudTrail. Anyone with SSM read access can recover them." -ForegroundColor Yellow

  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($localPath))
  $cmds = @(
    "cd $remoteDir",
    '[ -f .env ] && cp .env ".env.bak.$(date +%s)" || true',   # back up remote first
    "printf %s '$b64' | base64 -d > .env",
    'echo "wrote .env:" && wc -l .env',
    $reloadCmd                                                  # reload with new env
  )
  $r = Invoke-Ssm $cmds "push env + reload" $nameTag
  if ($r.Out) { Write-Host $r.Out }
  if ($r.Status -ne 'Success') { if ($r.Err) { Write-Host $r.Err -ForegroundColor Red }; Fail "push env status: $($r.Status)" }
  Write-Host "`nenv pushed and stack reloaded" -ForegroundColor Green
}

# Pull $remoteDir/.env from $nameTag down to $localPath, backing up any existing local copy.
function Pull-Env([string]$localPath, [string]$remoteDir, [string]$nameTag) {
  Step "pull env  ${nameTag}:$remoteDir/.env  ->  $localPath"
  $r = Invoke-Ssm @("cd $remoteDir", 'base64 -w0 .env') "pull env" $nameTag
  if ($r.Status -ne 'Success') { if ($r.Err) { Write-Host $r.Err -ForegroundColor Red }; Fail "pull env status: $($r.Status)" }
  $b64 = ($r.Out -replace '\s', '')
  if (-not $b64) { Fail "remote .env was empty or missing at $remoteDir/.env" }
  if (Test-Path $localPath) { Copy-Item $localPath "$localPath.bak" -Force }   # back up local first
  [IO.File]::WriteAllBytes($localPath, [Convert]::FromBase64String($b64))
  Write-Host "`nwrote $localPath (previous local saved as $localPath.bak)" -ForegroundColor Green
}

# ============================ MAIN ============================
$envOpCount = @($PushEnv, $PullEnv, $PushWorkerEnv, $PullWorkerEnv).Where({ $_ }).Count
if ($envOpCount -gt 1) { Fail "choose only one of -PushEnv / -PullEnv / -PushWorkerEnv / -PullWorkerEnv" }

# --- app box env ---
if ($PullEnv) { Pull-Env $LocalEnvPath $RemoteDeployDir $InstanceNameTag; Write-Host "`nDone: pulled env" -ForegroundColor Green; exit 0 }
if ($PushEnv) { Push-Env $LocalEnvPath $RemoteDeployDir $InstanceNameTag "docker compose up -d"; Write-Host "`nDone: pushed env + reload" -ForegroundColor Green; exit 0 }

# --- worker box env (/opt/app/.env via worker.env), reloaded with the worker compose file ---
if ($PullWorkerEnv) { Pull-Env $LocalWorkerEnvPath $WorkerRemoteDeployDir $WorkerInstanceNameTag; Write-Host "`nDone: pulled worker env" -ForegroundColor Green; exit 0 }
if ($PushWorkerEnv) { Push-Env $LocalWorkerEnvPath $WorkerRemoteDeployDir $WorkerInstanceNameTag "docker compose -f $WorkerComposeFile up -d"; Write-Host "`nDone: pushed worker env + reload" -ForegroundColor Green; exit 0 }

if (-not $Target) { Fail "specify -Target backend|frontend|worker|both|all, or an env op (-PushEnv/-PullEnv/-PushWorkerEnv/-PullWorkerEnv)" }

$services     = @()   # app-instance services (backend/frontend), built + pushed locally
$deployWorker = $false

# Local ECR login is only for local image builds (backend/frontend). The worker builds
# on the box and needs nothing on this machine, so skip it for a worker-only run.
if ($Target -in @('backend', 'frontend', 'both', 'all')) { Login-Ecr }
if ($Target -in @('backend', 'both', 'all')) { Build-Push-Backend; $services += $BackendService }
if ($Target -in @('frontend', 'both', 'all')) { Build-Push-Frontend; $services += $FrontendService }
if ($Target -in @('worker', 'all')) { $deployWorker = $true }

if ($SkipRemote) {
  Write-Host "`n-SkipRemote set: pushed local images to ECR (if any); server(s) untouched." -ForegroundColor Yellow
  if ($deployWorker) {
    Write-Host "  note: the worker builds and runs entirely on the server, so -SkipRemote skips it." -ForegroundColor Yellow
  }
}
else {
  if ($services.Count -gt 0) { Update-Remote $services }   # app box: pull + up
  if ($deployWorker) { Deploy-Worker }                     # GPU box: git + build + up
}

Write-Host "`nDone: $Target ($Tag)" -ForegroundColor Green
