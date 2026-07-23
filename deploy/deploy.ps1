<#
.SYNOPSIS
  Build -> push to ECR -> update the container on EC2, plus .env sync helpers.

.DESCRIPTION
  Runs from your local machine. Remote actions go over AWS SSM Run Command (not
  SSH), so nothing extra needs to be open on the instance.

  Actions (pick one):
    -Target backend|frontend|both   build+push image(s), then reload that service
    -PushEnv                        copy local .env -> remote, then reload the stack
    -PullEnv                        copy remote .env -> local (backs up the local one)

.EXAMPLE
  .\deploy.ps1 -Target backend
  .\deploy.ps1 -Target both
  .\deploy.ps1 -Target backend -SkipRemote                    # just build+push
  .\deploy.ps1 -PushEnv                                       # push .env + reload
  .\deploy.ps1 -PullEnv                                       # pull .env to local
  .\deploy.ps1 -Target frontend -FrontendPath D:\src\frontend # override repo path
#>
[CmdletBinding()]
param(
  [ValidateSet('backend', 'frontend', 'both')]
  [string]$Target,

  [switch]$PushEnv,
  [switch]$PullEnv,

  [string]$Tag = 'latest',

  # Full paths to the repos. Defaults are absolute; override if your checkout lives elsewhere.
  [string]$BackendPath  = 'C:\Users\Administrator\Desktop\backend',
  [string]$FrontendPath = 'C:\Users\Administrator\Desktop\frontend',

  # Local .env (the one docker-compose.yml reads). Defaults next to this script.
  [string]$LocalEnvPath = (Join-Path $PSScriptRoot '.env'),

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

# --- server ---
$InstanceNameTag = 'poc-prod-app-ec2-instance'   # EC2 Name tag; used to find the instance
# NOTE: this currently lives under the ssm-agent SNAP revision dir, which is NOT stable
# (the revision number changes on snap updates and the old dir is deleted). Move it to a
# stable path like /opt/app/deploy and update this line — see the move steps.
$RemoteDeployDir = '/var/snap/amazon-ssm-agent/13349/deploy'
# ===============================================================

function Fail($msg) { Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }
function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

function Get-InstanceId {
  $iid = aws ec2 describe-instances --profile $AwsProfile --region $Region `
    --filters "Name=tag:Name,Values=$InstanceNameTag" "Name=instance-state-name,Values=running" `
    --query "Reservations[].Instances[].InstanceId" --output text
  if ($LASTEXITCODE -ne 0) { Fail "ec2 describe-instances failed" }
  $iid = ($iid -split '\s+') | Where-Object { $_ } | Select-Object -First 1
  if (-not $iid) { Fail "no running instance tagged '$InstanceNameTag' found" }
  return $iid
}

# Run a list of shell lines on the instance via SSM. Returns Status/Out/Err.
# 'set -e' makes it fail-fast; PATH is set because Run Command shells are minimal.
function Invoke-Ssm([string[]]$commands, [string]$comment) {
  $iid = Get-InstanceId
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
  $pw | docker login --username AWS --password-stdin $Registry
  if ($LASTEXITCODE -ne 0) { Fail "docker login failed" }
}

function Build-Push-Backend {
  $image = "$Registry/${BackendRepo}:$Tag"
  Step "build backend -> $image"
  docker build --platform linux/amd64 -f (Join-Path $BackendPath $BackendDockerfile) -t $image $BackendPath
  if ($LASTEXITCODE -ne 0) { Fail "backend build failed" }
  Step "push $image"
  docker push $image
  if ($LASTEXITCODE -ne 0) { Fail "backend push failed" }
}

function Build-Push-Frontend {
  $image = "$Registry/${FrontendRepo}:$Tag"
  Step "build frontend -> $image (NEXT_PUBLIC_API_URL=$FrontendApiUrl)"
  docker build --platform linux/amd64 --build-arg "NEXT_PUBLIC_API_URL=$FrontendApiUrl" -t $image $FrontendPath
  if ($LASTEXITCODE -ne 0) { Fail "frontend build failed" }
  Step "push $image"
  docker push $image
  if ($LASTEXITCODE -ne 0) { Fail "frontend push failed" }
}

function Update-Remote([string[]]$services) {
  $svcList = $services -join ' '
  Step "SSM: update container(s) [$svcList]"
  $cmds = @(
    "cd $RemoteDeployDir",
    "aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $Registry",
    "docker compose pull $svcList",
    "docker compose up -d $svcList",
    'docker compose ps'
  )
  $r = Invoke-Ssm $cmds "deploy $svcList"
  if ($r.Out) { Write-Host $r.Out }
  if ($r.Status -ne 'Success') { if ($r.Err) { Write-Host $r.Err -ForegroundColor Red }; Fail "remote update status: $($r.Status)" }
  Write-Host "`nremote update: SUCCESS" -ForegroundColor Green
}

function Push-Env {
  if (-not (Test-Path $LocalEnvPath)) { Fail "local env not found: $LocalEnvPath" }
  Step "push env  $LocalEnvPath  ->  ${InstanceNameTag}:$RemoteDeployDir/.env  (+ reload)"
  Write-Host "    WARNING: .env contents pass through SSM command parameters, retained in SSM" -ForegroundColor Yellow
  Write-Host "    command history / CloudTrail. Anyone with SSM read access can recover them." -ForegroundColor Yellow

  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($LocalEnvPath))
  $cmds = @(
    "cd $RemoteDeployDir",
    '[ -f .env ] && cp .env ".env.bak.$(date +%s)" || true',   # back up remote first
    "printf %s '$b64' | base64 -d > .env",
    'echo "wrote .env:" && wc -l .env',
    'docker compose up -d'                                       # reload with new env
  )
  $r = Invoke-Ssm $cmds "push env + reload"
  if ($r.Out) { Write-Host $r.Out }
  if ($r.Status -ne 'Success') { if ($r.Err) { Write-Host $r.Err -ForegroundColor Red }; Fail "push env status: $($r.Status)" }
  Write-Host "`nenv pushed and stack reloaded" -ForegroundColor Green
}

function Pull-Env {
  Step "pull env  ${InstanceNameTag}:$RemoteDeployDir/.env  ->  $LocalEnvPath"
  $r = Invoke-Ssm @("cd $RemoteDeployDir", 'base64 -w0 .env') "pull env"
  if ($r.Status -ne 'Success') { if ($r.Err) { Write-Host $r.Err -ForegroundColor Red }; Fail "pull env status: $($r.Status)" }
  $b64 = ($r.Out -replace '\s', '')
  if (-not $b64) { Fail "remote .env was empty or missing at $RemoteDeployDir/.env" }
  if (Test-Path $LocalEnvPath) { Copy-Item $LocalEnvPath "$LocalEnvPath.bak" -Force }   # back up local first
  [IO.File]::WriteAllBytes($LocalEnvPath, [Convert]::FromBase64String($b64))
  Write-Host "`nwrote $LocalEnvPath (previous local saved as $LocalEnvPath.bak)" -ForegroundColor Green
}

# ============================ MAIN ============================
if ($PushEnv -and $PullEnv) { Fail "choose either -PushEnv or -PullEnv, not both" }

if ($PullEnv) { Pull-Env; Write-Host "`nDone: pulled env" -ForegroundColor Green; exit 0 }
if ($PushEnv) { Push-Env; Write-Host "`nDone: pushed env + reload" -ForegroundColor Green; exit 0 }

if (-not $Target) { Fail "specify -Target backend|frontend|both, or use -PushEnv / -PullEnv" }

$services = @()
Login-Ecr
if ($Target -eq 'backend' -or $Target -eq 'both') { Build-Push-Backend; $services += $BackendService }
if ($Target -eq 'frontend' -or $Target -eq 'both') { Build-Push-Frontend; $services += $FrontendService }

if ($SkipRemote) {
  Write-Host "`n-SkipRemote set: pushed to ECR, left the server untouched." -ForegroundColor Yellow
}
else {
  Update-Remote $services
}

Write-Host "`nDone: $Target ($Tag)" -ForegroundColor Green
