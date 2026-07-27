# Manual deploy (without the script)

This is the fallback for when `deploy.ps1` can't be used — you're debugging, the script
fails, or you need to run one step at a time and watch the raw output. It's the exact same
sequence the script automates. For the normal path, use [DEPLOY.md](DEPLOY.md).

**Everything here uses AWS SSM, not SSH.** There are no SSH keys or open ports.

---

## Setup

- AWS CLI v2 + the **`klearnnote`** profile (region `us-east-2`, account `376218549617`).
- **Session Manager plugin** for interactive shells:
  https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
- For backend/frontend builds: **Docker Desktop** running locally.

Reference values:

| Thing | Value |
|---|---|
| Region / Account | `us-east-2` / `376218549617` |
| ECR registry | `376218549617.dkr.ecr.us-east-2.amazonaws.com` |
| App instance (Name tag) | `poc-prod-app-ec2-instance` |
| Worker instance (Name tag) | `poc-prod-worker-ec2-instance` |
| ECR repos | `poc-prod-api`, `poc-prod-frontend`, `poc-prod-worker` |

Find an instance id by tag:
```bash
aws ec2 describe-instances --profile klearnnote --region us-east-2 \
  --filters "Name=tag:Name,Values=poc-prod-worker-ec2-instance" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" --output text
```

Open an interactive shell on a box (runs as `ssm-user`; use `sudo` for docker):
```bash
aws ssm start-session --profile klearnnote --region us-east-2 --target <instance-id>
```

---

## A. Backend or frontend (build locally → ECR → app box)

These images are built on your machine and pulled by the app server.

### 1. Build + push (on your machine)
```bash
REG=376218549617.dkr.ecr.us-east-2.amazonaws.com

# log in to ECR
aws ecr get-login-password --region us-east-2 --profile klearnnote \
  | docker login --username AWS --password-stdin $REG

# backend (run from the backend repo root)
docker build --platform linux/amd64 -f Dockerfile.api -t $REG/poc-prod-api:latest .
docker push $REG/poc-prod-api:latest

# frontend (run from the frontend repo root; API URL is baked in at build time)
docker build --platform linux/amd64 --build-arg NEXT_PUBLIC_API_URL=https://api.klearnote.ai \
  -t $REG/poc-prod-frontend:latest .
docker push $REG/poc-prod-frontend:latest
```

### 2. Reload on the app box
Open a session on `poc-prod-app-ec2-instance`, then (the compose stack lives in the
directory the script calls `$RemoteDeployDir`):
```bash
sudo -i
cd <deploy-dir>            # where docker-compose.yml lives on the app box
REG=376218549617.dkr.ecr.us-east-2.amazonaws.com
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin $REG

docker compose pull api            # or: frontend
docker compose up -d --force-recreate api
docker compose ps
```
Service names are `api` and `frontend`. Use `--force-recreate` so the `:latest` tag actually
swaps to the freshly pulled image.

---

## B. Worker (built ON the GPU box)

Your laptop can't build the CUDA image — the GPU box builds it from source. There is **no
ECR push/pull** for the worker; compose runs the locally built image.

Open a session on `poc-prod-worker-ec2-instance`, then:

```bash
sudo -i

# 1. sync the source (durable clone lives here)
cd /opt/app/backend
git fetch --all --prune
git checkout feat/refresh-tokens-and-invoices     # <- the branch you want to deploy, here is just an example
git reset --hard origin/feat/refresh-tokens-and-invoices 
git log -1 --oneline                              # confirm the commit

# 2. build the worker image on the box (cu128 = CUDA wheels matching the T4 driver)
REG=376218549617.dkr.ecr.us-east-2.amazonaws.com
docker build -f Dockerfile.worker \
  --build-arg TORCH_INDEX_URL=https://download.pytorch.org/whl/cu128 \
  -t $REG/poc-prod-worker:latest .

# 3. restart the 4 replicas from the new image
cd /opt/app
docker compose -f worker-compose.yml up -d --force-recreate
docker compose -f worker-compose.yml ps

# 4. clean up old image layers
docker image prune -f
```

Check it's healthy:
```bash
docker compose -f /opt/app/worker-compose.yml logs --since 5m    # recent logs
nvidia-smi                                                       # should show ~4 python procs on the GPU
```

### If `/opt/app/backend` is missing (e.g. after a server rebuild)

The worker needs a git clone on the box before it can build. Clone it **once**, with
credentials, on a stable path (root-owned, since deploys run as root):
```bash
sudo git clone <authenticated-repo-url> /opt/app/backend
```
> Prefer an SSH **deploy key** (repo-scoped, read-only) over a personal access token in the
> URL. A token embedded in the remote URL is readable by anyone who can reach the box.

---

## C. Editing `.env` by hand

Each box keeps its own `.env`. Worker: `/opt/app/.env`. App box: in its deploy dir.

```bash
# on the box
sudo -i
cd /opt/app                       # (or the app deploy dir)
cp .env .env.bak.$(date +%s)      # always back up first
nano .env                         # make changes

# apply
docker compose -f worker-compose.yml up -d      # worker
# or, on the app box:
docker compose up -d
```

Compose recreates containers whose `env_file` changed. `.env` is never committed to git.

---

## Concepts cheat-sheet

- **ECR** — private Docker registry. Backend/frontend go through it; the worker does not.
- **SSM Session / Run Command** — remote shell + remote commands over AWS, no SSH.
- **Run Command runs as `root`; `start-session` runs as `ssm-user`** (needs `sudo` for docker).
- **`--force-recreate`** — forces containers to relaunch on a new `:latest` image (a plain
  `up -d` can leave the old one running).
- **Worker = 4 replicas** sharing one GPU; the job queue is Postgres (`SELECT ... FOR UPDATE
  SKIP LOCKED`), so replicas never collide and dead ones are auto-requeued.
