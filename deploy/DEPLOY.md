# Deploying with `deploy.ps1`

A one-stop script to ship the **backend**, **frontend**, and **worker** to production, plus
sync their `.env` files. This is the normal, everyday way to deploy. If the script ever
breaks and you need to do it by hand, see [MANUAL-DEPLOY.md](MANUAL-DEPLOY.md).

---

## 1. The mental model (read this once)

We run **three services on two servers**, all in AWS (`us-east-2`, account `376218549617`):

| Service | Built where | Lives on | How it runs |
|---|---|---|---|
| **backend** (FastAPI) | your laptop → ECR | app instance (`poc-prod-app-ec2-instance`, `t3.large`) | `docker compose` |
| **frontend** (Next.js) | your laptop → ECR | app instance (same box) | `docker compose` |
| **worker** (GPU audio separation) | **on the GPU server** | worker instance (`poc-prod-worker-ec2-instance`, `g4dn.xlarge`) | `docker compose`, 4 replicas |

A few concepts that make everything else click:

- **ECR** = AWS's private Docker registry. `backend`/`frontend` images are built on your
  machine and **pushed** to ECR; the app server **pulls** them. Repos: `poc-prod-api`,
  `poc-prod-frontend`.
- **SSM Run Command** = how the script runs commands on the servers **without SSH**. There
  are no open SSH ports; access is entirely through AWS. That's why you only need the AWS
  CLI + permissions, not a key file.
- **The worker is different.** It's a heavy CUDA/PyTorch image your laptop can't build, so
  the script tells the **GPU box to build it itself** (git pull → `docker build` → restart).
  Nothing is pushed to ECR for the worker.
- **`.env` files** hold secrets/config and live **on the servers**, not in git. The app box
  and worker box each have their own `.env`. The script can push/pull them.

---

## 2. One-time setup

1. **AWS CLI v2** installed.
2. **The `klearnnote` AWS profile** configured with your credentials:
   ```bash
   aws configure --profile klearnnote
   ```
   You need IAM permissions for `ec2:DescribeInstances` and `ssm:SendCommand` /
   `ssm:GetCommandInvocation` (ask an admin if `aws sts get-caller-identity --profile klearnnote` fails).
3. **Docker Desktop** running — only needed if you deploy **backend** or **frontend**
   (those build locally). Not needed for worker-only or env-only commands.
4. Clone this repo. The script defaults assume the backend is at
   `C:\Users\Administrator\Desktop\backend` and frontend at `...\frontend` — override with
   `-BackendPath` / `-FrontendPath` if yours live elsewhere.

Verify you're wired up:
```bash
aws sts get-caller-identity --profile klearnnote
```

---

## 3. Deploying code

Run from the `deploy/` folder. Pick **one** target:

```bash
.\deploy.ps1 -Target backend     # build+push backend, reload it on the app box
```
```bash
.\deploy.ps1 -Target frontend    # build+push frontend, reload it on the app box
```
```bash
.\deploy.ps1 -Target both        # backend + frontend
```
```bash
.\deploy.ps1 -Target worker      # git-sync + build + restart the worker ON the GPU box
```
```bash
.\deploy.ps1 -Target all         # backend + frontend + worker
```

### What each target actually does

**`backend` / `frontend` / `both`**
1. Log in to ECR from your machine.
2. `docker build` the image locally (`--platform linux/amd64`), then `docker push` to ECR.
3. Over SSM, tell the app box to `docker compose pull` + `up -d --force-recreate` that service.

**`worker`** (no local build — it all happens on the GPU box, via one SSM call)
1. `git fetch` + `checkout` + `reset --hard` the chosen branch in `/opt/app/backend`.
2. `docker build` the worker image **on the box** (with the cu128 CUDA wheels).
3. `docker compose -f worker-compose.yml up -d --force-recreate` → restarts all **4 replicas**
   onto the new image, then prunes old layers.

> ⚠️ The worker build takes several minutes (PyTorch is big). The script waits and streams
> the output — don't kill it. `--force-recreate` briefly interrupts any in-progress audio
> jobs; they get automatically requeued.

### Choosing the worker branch

The worker builds from a git branch **on the server**. Default is the branch currently in
production; deploy a different one with `-Branch`:

```bash
.\deploy.ps1 -Target worker -Branch mvp-v1
```

### Handy flags

| Flag | Meaning |
|---|---|
| `-Tag <name>` | Image tag (default `latest`). |
| `-Branch <name>` | Worker git branch to build (worker target only). |
| `-SkipRemote` | Build + push to ECR but **don't** touch the servers (backend/frontend only). |
| `-BackendPath` / `-FrontendPath` | Point at your local repos if not in the default location. |

---

## 4. Managing `.env`

The `.env` files live on the servers. Edit them by pulling a copy down, changing it, and
pushing it back. **Push reloads the affected containers.** Each push backs up the previous
remote copy first; each pull backs up your local copy first.

**App box** (backend + frontend), uses local `.env` next to the script:
```bash
.\deploy.ps1 -PullEnv     # server .env  ->  local .env
.\deploy.ps1 -PushEnv     # local .env   ->  server, then reload
```

**Worker box**, uses local `worker.env` next to the script:
```bash
.\deploy.ps1 -PullWorkerEnv   # worker /opt/app/.env  ->  local worker.env
.\deploy.ps1 -PushWorkerEnv   # local worker.env      ->  worker box, then reload
```

Typical edit flow:
```bash
.\deploy.ps1 -PullWorkerEnv        # get the current file
# ...edit worker.env...
.\deploy.ps1 -PushWorkerEnv        # apply it
```

> 🔒 `.env` contents pass through SSM command parameters, which AWS retains in command
> history / CloudTrail. Treat anyone with SSM read access as able to see them. Never commit
> `.env` or `worker.env` to git.

---

## 5. Quick reference

```
CODE
  .\deploy.ps1 -Target backend|frontend|worker|both|all
  .\deploy.ps1 -Target worker -Branch <branch>

ENV
  .\deploy.ps1 -PushEnv        / -PullEnv          # app box
  .\deploy.ps1 -PushWorkerEnv  / -PullWorkerEnv    # worker box
```

You can only run **one** action per invocation.

---

## 6. If something goes wrong

- **`no running instance tagged ... found`** — the target EC2 box is stopped, or your
  `klearnnote` profile points at the wrong account/region.
- **`docker login failed` / push fails** — re-check the profile; the script logs in to ECR
  for you, so this is almost always credentials.
- **Worker: `no git checkout at /opt/app/backend`** — the server's clone is missing (e.g.
  after a rebuild). It must be cloned once with credentials before the script can deploy —
  see [MANUAL-DEPLOY.md](MANUAL-DEPLOY.md).
- **Worker build fails on a torch/CUDA wheel** — the cu128 index may not match the GPU
  driver; check `$WorkerTorchIndexUrl` in the script and the driver on the box (`nvidia-smi`).
- **Anything deeper** — fall back to [MANUAL-DEPLOY.md](MANUAL-DEPLOY.md) to run the same
  steps by hand and see the raw output.
