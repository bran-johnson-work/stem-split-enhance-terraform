module "vpc" {
  source = "../../../modules/vpc"

  env     = var.env
  project = var.project
  region  = var.region

  vpc_cidr     = "10.0.0.0/16"
  public_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  app_cidrs    = ["10.0.3.0/24", "10.0.4.0/24"]
  data_cidrs   = ["10.0.5.0/24", "10.0.6.0/24"]

  only_one_nat_gateway = true
  enable_nat_gateway = false
}
