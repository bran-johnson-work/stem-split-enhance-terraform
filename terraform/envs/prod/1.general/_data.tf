data "aws_caller_identity" "current" {}

# data "aws_route53_zone" "selected" {
#   name         = var.domain_name
#   private_zone = false
# }

data "aws_ami" "ubuntu_24_04_arm64" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_elb_service_account" "main" {}

data "sops_file" "secret_enc" {
  source_file = "${path.module}/../../../../sops/secrets.prod.yaml"
}
