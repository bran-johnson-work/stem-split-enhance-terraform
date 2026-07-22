#modules/ecs/_versions.tf
terraform {
  required_version = ">= 1.3.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.48"
    }
    template = "~> 2.2.0"
  }
}
