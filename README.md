# POC Infrastructure

Terraform infrastructure for the POC project.

## Structure

```
terraform/
├── modules/          # Reusable modules
└── envs/prod/
    ├── 1.general/    # VPC, ACM, Route53, KMS, S3, Bastion
    └── 2.application/# ECS, ALB, Aurora, EC2 Worker, CloudFront, S3
```

## Prerequisites

1. Create S3 bucket for state: `poc-prod-iac-state` (versioning enabled)
2. Create EC2 key pair: `poc-prod-keypair` in ap-northeast-1
3. Configure SOPS with your KMS key ARN in `sops/.sops.yaml`
4. Encrypt secrets: `cd sops && sops --encrypt --in-place secrets.prod.yaml`

## Usage

Apply layers in order:

```bash
# Layer 1
cd terraform/envs/prod/1.general
terraform init
terraform plan
terraform apply

# Layer 2
cd ../2.application
terraform init
terraform plan
terraform apply
```

## Deployment (API)

```bash
# Build and push to ECR
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com
docker build -t poc-prod-api .
docker tag poc-prod-api:latest ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/poc-prod-api:latest
docker push ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/poc-prod-api:latest

# Force new deployment
aws ecs update-service --cluster poc-prod-api-ecs-cluster --service poc-prod-api-ecs-service --force-new-deployment
```
