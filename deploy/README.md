# Deploy

Local tooling to build, publish, and update the KlearNote MVP stack running on the
single EC2 app host (`i-0c1c7c5efbefbef15`, tag `poc-prod-app-ec2-instance`).

All remote actions go over **AWS SSM Run Command**, not SSH — the app host's
security group only opens 80/443, and nothing else needs to be exposed.

## Contents

| File | Purpose |
|------|---------|
| `deploy.ps1` | Build → push to ECR → update the container on EC2; plus `.env` sync |
| `docker-compose.yml` | The stack: `migrate` → `api` + `frontend` behind `caddy` (TLS) |
| `.env` | Backend runtime config (secrets). **Not committed.** Lives on the server too |
| `.env.example` | Template for `.env` |

## Prerequisites

**Local machine (Windows / PowerShell):**
- Docker Desktop running (produces `linux/amd64` images — matches the host)
- AWS CLI v2, with the `klearnnote` profile configured
- That profile needs: ECR push, `ec2:DescribeInstances`, `ssm:SendCommand`,
  `ssm:GetCommandInvocation`

**Server (already set up):**
- Docker Engine + Compose plugin, SSM agent (installed via the instance user-data)
- ECR login kept fresh (12h token) — via the cron job or the ECR credential helper

## Quick start

```powershell
cd C:\Users\Administrator\Desktop\terraform\deploy

.\deploy.ps1 -Target backend      # build+push api, reload the api container
.\deploy.ps1 -Target frontend     # build+push frontend, reload it
.\deploy.ps1 -Target both         # both
```

## `deploy.ps1` reference

### Actions (pick one)

| Command | What it does |
|---------|--------------|
| `-Target backend` | Build `poc-prod-api`, push, then `compose pull/up` the `api` service |
| `-Target frontend` | Build `poc-prod-frontend` (bakes `NEXT_PUBLIC_API_URL`), push, reload |
| `-Target both` | Both of the above |
| `-PushEnv` | Copy local `.env` → server, then **reload the stack** |
| `-PullEnv` | Copy server `.env` → local (backs up your local copy first) |

### Options

| Option | Default | Notes |
|--------|---------|-------|
| `-Tag <t>` | `latest` | Image tag to build/push |
| `-SkipRemote` | off | Build + push only; don't touch the server |
| `-BackendPath <path>` | `C:\Users\Administrator\Desktop\backend` | Full path to the backend repo |
| `-FrontendPath <path>` | `C:\Users\Administrator\Desktop\frontend` | Full path to the frontend repo |
| `-LocalEnvPath <path>` | `.env` next to the script | Which local `.env` the sync uses |

### Examples

```powershell
.\deploy.ps1 -Target backend -SkipRemote                    # build+push, no deploy
.\deploy.ps1 -Target frontend -FrontendPath D:\src\frontend # override repo path
.\deploy.ps1 -PushEnv                                       # push .env + reload
.\deploy.ps1 -PullEnv                                       # pull server .env to local
```

## How a deploy works

1. `docker login` to ECR (`376218549617.dkr.ecr.us-east-2.amazonaws.com`)
2. `docker build --platform linux/amd64` the selected image(s)
   - frontend also gets `--build-arg NEXT_PUBLIC_API_URL=https://api.klearnote.ai`
     (compiled into the client bundle — rebuild whenever that origin changes)
3. `docker push` to ECR
4. Over SSM: on the host, `docker compose pull <svc>` then `up -d <svc>`

A **backend** deploy re-runs migrations automatically: `api` depends on the one-shot
`migrate` service (`alembic upgrade head`), so `up -d api` recreates it after migrate
completes.

## `.env` sync

- **`-PushEnv`** writes local `.env` → server, backing the server copy up to
  `.env.bak.<timestamp>` first, then runs `docker compose up -d` so the new values
  take effect. Reload happens **only** on push (that's where the containers run).
- **`-PullEnv`** writes server `.env` → local, backing your local copy up to
  `.env.bak` first. It does **not** reload anything (nothing runs locally).

After a pull:
- `.env` = the content just pulled from the server
- `.env.bak` = your previous local `.env`

> ⚠️ **Push exposes secrets in SSM history.** The `.env` is base64'd into the SSM
> command parameters, which AWS retains in command history / CloudTrail — anyone
> with SSM read access can recover them. Acceptable for MVP; if not, stage the file
> through an SSE-encrypted S3 object instead.

## Server deploy directory (important)

`$RemoteDeployDir` in `deploy.ps1` must point at where `docker-compose.yml` and
`.env` live on the host. It is currently:

```
/var/snap/amazon-ssm-agent/13349/deploy
```

**This is not a stable path** — `13349` is the ssm-agent snap revision and gets
deleted when the snap updates, taking `.env` and Caddy's issued certs with it. Move
the deploy dir to a durable location and update the one line:

```bash
# on the host
sudo mkdir -p /opt/app
sudo cp -a /var/snap/amazon-ssm-agent/13349/deploy /opt/app/deploy
cd /opt/app/deploy
sudo docker compose up -d      # project name stays "deploy"; containers are reused
```
Then set `$RemoteDeployDir = '/opt/app/deploy'`.

## Manual fallback (on the host)

```bash
cd <deploy dir>
aws ecr get-login-password --region us-east-2 | sudo docker login --username AWS \
  --password-stdin 376218549617.dkr.ecr.us-east-2.amazonaws.com
sudo docker compose pull api        # or frontend
sudo docker compose up -d api
sudo docker compose ps
sudo docker compose logs -f api
```

## Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| `Error parsing parameter '--parameters' ... 'ï'` | UTF-8 BOM in the temp file. Already fixed in the script (writes UTF-8 without BOM). |
| `cd: can't cd to <dir>` | `$RemoteDeployDir` is wrong — point it at the real deploy dir. |
| `no basic auth credentials` on pull | ECR token expired / logged in as a different user. Re-run the ECR login as the same user that pulls (root via SSM). |
| `no running instance tagged ...` | Instance stopped, or the `Name` tag changed. |
| Frontend shows old API URL | `NEXT_PUBLIC_API_URL` is baked at build time — rebuild + repush the frontend. |
