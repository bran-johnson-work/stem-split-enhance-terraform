#modules/s3/_versions.tf
terraform {
  required_version = ">= 1.3.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.22"
    }
    template = "~> 2.0"
  }
}
