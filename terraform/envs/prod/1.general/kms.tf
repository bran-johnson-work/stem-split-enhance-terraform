module "kms_shared" {
  source = "../../../modules/kms"

  env     = var.env
  project = var.project
  region  = var.region

  name                = "shared"
  enable_key_rotation = true
}
