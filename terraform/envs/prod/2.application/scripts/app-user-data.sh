#!/bin/bash
set -euxo pipefail

# ---------------------------------------------------------------------------
# App host bootstrap (Ubuntu 22.04, amd64)
# Installs the SSM agent (for shell access without SSH) and Docker + the
# Compose plugin, since the frontend/backend run via `docker compose`.
# Runs once at first boot; logs to /var/log/cloud-init-output.log.
# ---------------------------------------------------------------------------

export DEBIAN_FRONTEND=noninteractive

apt-get update -y

# --- SSM agent -------------------------------------------------------------
# Canonical's AMI ships it as a snap; ensure it's present and running so the
# instance registers with Systems Manager (Session Manager shell, no SSH).
if ! snap list amazon-ssm-agent >/dev/null 2>&1; then
  snap install amazon-ssm-agent --classic
fi
snap start amazon-ssm-agent || true

# --- Docker Engine + Compose plugin ---------------------------------------
apt-get install -y ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

# Let the default 'ubuntu' user run docker without sudo.
usermod -aG docker ubuntu || true

echo "app-host bootstrap complete"
