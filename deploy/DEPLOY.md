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
| **worker** (GPU audio separation) | **on the GPU server** | worker instance (`poc-prod-worker-ec2-instance`, `g4dn.xlarge`) | `docker compose`, 2 fleets / 4 replicas total |

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
2. `docker build` **two** images on the box (both with the cu128 CUDA wheels):
   `…:v1-latest` from `Dockerfile.worker` and `…:v2-latest` from `Dockerfile.worker.v2`.
   They share every torch layer, so v2 adds only its own dependencies.
3. `docker compose -f worker-compose.yml up -d --force-recreate` → restarts both fleets
   onto the new images, prints `nvidia-smi`, then prunes old layers.

> ⚠️ The worker build takes several minutes (PyTorch is big). The script waits and streams
> the output — don't kill it. `--force-recreate` briefly interrupts any in-progress audio
> jobs; they get automatically requeued.

Deploying a branch that has no `Dockerfile.worker.v2` is safe: the script skips the v2
build and brings up `worker-v1` only, rather than failing the deploy.

### The two worker fleets

| Fleet | Image | Claims | Models |
|---|---|---|---|
| `worker-v1` | `…:v1-latest` | `engine_version = v1` | HT-Demucs (what has always run here) |
| `worker-v2` | `…:v2-latest` | `engine_version = v2` | Mel-Band RoFormer vocals + HT-Demucs rhythm |

They share the one Postgres queue and are separated **only** by
`WORKER_ENGINE_VERSIONS`. Both poll `processing_jobs` with `FOR UPDATE SKIP LOCKED`
filtered on that list, so a v1 container can never claim a v2 job — it has no RoFormer
weights and would run the wrong model while recording the result as v2. **Never widen
`worker-v1` to `v1,v2`.**

> 🎛️ **Replica budget.** This box has **one T4 with 16 GB of VRAM, shared by every
> replica.** The split defaults to **3 × v1 + 1 × v2** (still 4 total) with
> `V2_BATCH_SIZE=1`, because a v2 replica additionally holds a RoFormer model. A 2/2 split
> at the app's default batch size of 4 is the most likely way to OOM this card. Measure with
> `nvidia-smi` across a full job before raising `WORKER_V2_REPLICAS`.

Override per-deploy on the box's `.env` (or inline): `WORKER_V1_REPLICAS`,
`WORKER_V2_REPLICAS`, `V2_BATCH_SIZE`, `V2_OVERLAP`.

Turning the comparison on for users is a **backend** env change, not a worker one —
`ENGINE_AB_ENABLED` / `ENGINE_AB_PERCENT` / `ENGINE_AB_USER_ALLOWLIST` on the app box, then
`.\deploy.ps1 -PushEnv`. See `backend/docs/deploy-v1-v2-workers.md` for the rollout stages.

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

## 3b. Frontend env — build-time vs runtime

The frontend does **not** read `.env` on the server, and this trips people up. Next.js
inlines every `NEXT_PUBLIC_*` variable into the **client bundle when the image is built**.
By the time the container starts, those values are already compiled into JavaScript that
has shipped to the browser — setting them in the environment then has no effect at all.

So frontend config splits in two:

| Kind | Where it is set | Takes effect |
|---|---|---|
| `NEXT_PUBLIC_*` | `--build-arg` in `deploy.ps1` → `frontend/Dockerfile` | on the next `-Target frontend` build |
| Server-only (e.g. `DEMO_ORIGIN`) | `environment:` on the `frontend` service in `docker-compose.yml`, interpolated from `.env` | on the next `-PushEnv` / container restart |

Current build args:

| Variable | Value | Purpose |
|---|---|---|
| `NEXT_PUBLIC_API_URL` | `https://api.klearnote.ai` | the API origin the browser calls |
| `NEXT_PUBLIC_DEMO_URL` | `-DemoUrl` parameter | the Streamlit demo framed by `/demo` |

> ⚠️ `frontend/Dockerfile` gives `NEXT_PUBLIC_DEMO_URL` a **default** of
> `https://demo.klearnote.ai`. Nothing serves that hostname, so any build that forgets the
> build arg silently ships a blank `/demo` frame. `deploy.ps1` now always passes it.

Free ngrok tunnels get a new hostname each time the agent restarts, and the value is baked
in, so **every rotation needs a frontend rebuild**:

```bash
.\deploy.ps1 -Target frontend -DemoUrl https://<new-id>.ngrok-free.app
```

The app never frames a plain-HTTP or free-ngrok address directly — those route through the
same-origin proxy at `/api/audio-proxy` (`frontend/proxy.ts`), which is what defeats both
mixed content and ngrok's browser interstitial. So `-DemoUrl` accepts `http://<ip>:<port>`,
an ngrok URL, or a real HTTPS origin, and the app picks the right strategy for each.

To repoint the tunnel **without** rebuilding, set `DEMO_ORIGIN` in the app box's `.env` and
run `-PushEnv`. That only moves where the proxy forwards; the address shown in the demo's
toolbar and its "open in new tab" link still come from the baked-in value.

---

## 4. Managing `.env`

The `.env` files live on the servers. Edit them by pulling a copy down, changing it, and
pushing it back. **Push reloads the affected containers.** Each push backs up the previous
remote copy first; each pull backs up your local copy first.

**App box**, uses local `.env` next to the script.

> This file configures the **backend only** — `api` and `migrate` are the only services
> with `env_file: .env`. The frontend does not read it and never has: its `NEXT_PUBLIC_*`
> settings are baked into the image at build time (§3b), and the one runtime key it does
> use (`DEMO_ORIGIN`) is passed explicitly in `docker-compose.yml` so the database
> password, Stripe keys and `SECRET_KEY` are not handed to a public-facing Node process.
> Verify any time with `docker compose config`.
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
