#############################
# Security Group — GPU worker
#############################
# No ingress at all: SSH is intentionally closed. Shell access is via SSM Session
# Manager (outbound only). Egress defaults to allow-all (module default) so the box
# can reach ECR / apt / NVIDIA repos over the internet gateway.
module "security_group_worker" {
  source = "../../../modules/security-group"

  env     = var.env
  project = var.project

  name          = "ec2-worker"
  vpc_id        = data.terraform_remote_state.general.outputs.vpc_id
  ingress_rules = []
}

#############################
# IAM role — GPU worker
#############################
# SSM (shell + Run Command), ECR pull (worker image), S3 read/write (media + stems),
# CloudWatch agent. No DB creds here — the worker reaches Aurora over the network
# (it is in security_group_worker, which the Aurora SG already allows on 5432).
module "iam_role_ec2_worker" {
  source = "../../../modules/iam-role"

  env     = var.env
  project = var.project

  name    = "ec2-worker"
  service = "ec2"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : { "Service" : "ec2.amazonaws.com" },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  iam_default_policy_arn = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
  iam_custom_policy = {
    template = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "ECRPull",
          "Effect" : "Allow",
          "Action" : [
            "ecr:GetAuthorizationToken",
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchCheckLayerAvailability"
          ],
          "Resource" : "*"
        },
        {
          "Sid" : "S3BucketLevel",
          "Effect" : "Allow",
          "Action" : [
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads"
          ],
          "Resource" : [
            module.s3_media.s3_bucket_arn,
            module.s3_stems.s3_bucket_arn
          ]
        },
        {
          "Sid" : "S3ObjectLevel",
          "Effect" : "Allow",
          "Action" : [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:AbortMultipartUpload",
            "s3:ListMultipartUploadParts"
          ],
          "Resource" : [
            "${module.s3_media.s3_bucket_arn}/*",
            "${module.s3_stems.s3_bucket_arn}/*"
          ]
        }
      ]
    })
  }
  iam_instance_profile = true
}

#############################
# EC2 instance — GPU worker
#############################
module "ec2_worker" {
  source = "../../../modules/ec2-instance"

  env     = var.env
  project = var.project

  name          = "worker"
  ami_id        = data.aws_ami.ubuntu_22.id
  instance_type = "g4dn.xlarge"
  # A keypair is still assigned (module requirement), but SSH is unreachable because
  # the security group opens no inbound ports — access is SSM-only.
  key_name           = "${var.project}-${var.env}-keypair"
  security_group_ids = [module.security_group_worker.security_group_id]
  # Public subnet: egress goes out the internet gateway (there is no NAT), which is
  # what lets this box reach ECR / apt / the NVIDIA repos. S3 still resolves through
  # the gateway endpoint. map_public_ip_on_launch = true gives it a public IP (no EIP,
  # so it changes on stop/start — fine, nothing connects TO the worker).
  subnet_id            = data.terraform_remote_state.general.outputs.subnet_public_id[0]
  iam_instance_profile = module.iam_role_ec2_worker.iam_instance_profile_id
  root_block_device = {
    volume_type = "gp3"
    volume_size = 50
  }
  monitoring = false
  user_data  = file("${path.module}/scripts/worker-user-data.sh")
  # The worker runs the CUDA container on the Docker bridge; hop limit 2 lets
  # in-container boto3 reach the instance profile via IMDS for S3.
  metadata_hop_limit = 2
}
