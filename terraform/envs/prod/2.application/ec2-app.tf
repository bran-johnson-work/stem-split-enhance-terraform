#############################
# Security Group — app host
#############################
# Public-facing host running the frontend + backend via docker compose.
# Ingress is open to the internet on 80/443 only. No SSH — shell access is via
# SSM Session Manager (outbound), so 22 stays closed.
module "security_group_app" {
  source = "../../../modules/security-group"

  env     = var.env
  project = var.project

  name   = "app"
  vpc_id = data.terraform_remote_state.general.outputs.vpc_id
  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    }
  ]
}

#############################
# IAM role — app host
#############################
# SSM for shell access, ECR pull for the backend image, and S3 read/write on the
# media + stems buckets (same object actions the app's storage layer uses).
module "iam_role_app" {
  source = "../../../modules/iam-role"

  env     = var.env
  project = var.project

  name    = "app"
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
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
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
# EC2 instance — app host
#############################
module "ec2_app" {
  source = "../../../modules/ec2-instance"

  env     = var.env
  project = var.project

  name                 = "app"
  ami_id               = data.aws_ami.ubuntu_22.id
  instance_type        = "t3.large"
  key_name             = "${var.project}-${var.env}-keypair"
  security_group_ids   = [module.security_group_app.security_group_id]
  subnet_id            = data.terraform_remote_state.general.outputs.subnet_public_id[0]
  iam_instance_profile = module.iam_role_app.iam_instance_profile_id
  root_block_device = {
    volume_type = "gp3"
    volume_size = 50
  }
  monitoring = false
  user_data  = file("${path.module}/scripts/app-user-data.sh")
  create_eip = true
  # api/frontend/caddy run as containers on the Docker bridge; hop limit 2 lets
  # in-container boto3 reach the instance profile via IMDS.
  metadata_hop_limit = 2
}
