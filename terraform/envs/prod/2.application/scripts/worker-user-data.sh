#!/bin/bash
# GPU worker bootstrap (Ubuntu 22.04, amd64, g4dn.xlarge = NVIDIA T4 / Turing).
# Installs SSM, Docker, the NVIDIA driver + Container Toolkit, and the AWS CLI so the
# host can run the CUDA worker image with `docker run --gpus all`. Reboots at the end
# to load the freshly built NVIDIA kernel module. cloud-init runs this once, so the
# reboot does not loop.
#
# Loaded via Terraform file() (NOT templatefile), so ${...} and $(...) are passed
# through literally and evaluated on the instance.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "worker init start: $(date -u)"

apt-get update
apt-get upgrade -y
apt-get install -y ca-certificates curl gnupg unzip

# --- SSM agent (Canonical AMI ships it as a snap; ensure it's up) ---
snap install amazon-ssm-agent --classic 2>/dev/null || true
snap start amazon-ssm-agent || true

# --- AWS CLI v2 (not preinstalled on the base AMI; needed for ECR login) ---
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
export PATH=/usr/local/bin:$PATH

# --- Docker Engine + Compose plugin ---
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable --now docker
usermod -aG docker ubuntu || true

# --- NVIDIA driver (current recommended, via NVIDIA's CUDA apt repo) ---
# 'cuda-drivers' is a metapackage that pulls the latest recommended driver, which
# supports the CUDA 12.6/12.8 runtimes bundled in the worker's torch wheels (cu126/
# cu128). We install the DRIVER only, not the full CUDA toolkit — the CUDA runtime
# ships inside the torch wheels. DKMS builds the kernel module; the reboot loads it.
apt-get install -y linux-headers-"$(uname -r)" build-essential dkms
curl -fsSL -o /tmp/cuda-keyring.deb \
  https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
dpkg -i /tmp/cuda-keyring.deb
apt-get update
apt-get install -y cuda-drivers

# --- NVIDIA Container Toolkit (exposes the GPU to Docker: `docker run --gpus all`) ---
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  > /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update
apt-get install -y nvidia-container-toolkit
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

# --- CloudWatch agent (mem + disk; EC2 doesn't report these natively) ---
curl -fsSL https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb \
  -o /tmp/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb
cat <<'EOF' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": { "metrics_collection_interval": 300, "run_as_user": "root" },
  "metrics": {
    "append_dimensions": { "InstanceId": "${aws:InstanceId}" },
    "metrics_collected": {
      "mem":  { "measurement": [ {"name": "mem_used_percent", "rename": "MemoryUtilization", "unit": "Percent"} ], "metrics_collection_interval": 300 },
      "disk": { "measurement": [ {"name": "used_percent", "rename": "DiskSpaceUtilization", "unit": "Percent"} ], "metrics_collection_interval": 300, "resources": ["/"] }
    }
  }
}
EOF
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json || true

# --- ECR login convenience (token lasts 12h; add a cron/cred-helper for longevity) ---
REGION="us-east-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com" || true

mkdir -p /opt/app

echo "worker init done: $(date -u) — rebooting to load the NVIDIA kernel module"
systemctl reboot
