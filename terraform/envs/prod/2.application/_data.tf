data "terraform_remote_state" "general" {
  backend = "s3"
  config = {
    bucket = "poc-prod-iac-state"
    key    = "general/terraform.prod.tfstate"
    region = var.region
  }
}

data "aws_caller_identity" "current" {}

data "sops_file" "secret_enc" {
  source_file = "${path.module}/../../../../sops/secrets.prod.yaml"
}

# TODO(domain): no hosted zone exists yet. Uncomment once the domain is registered.
# While absent this data source fails at plan time and blocks the entire stack.
# data "aws_route53_zone" "selected" {
#   name         = var.domain_name
#   private_zone = false
# }

data "aws_ami" "ubuntu_22" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
