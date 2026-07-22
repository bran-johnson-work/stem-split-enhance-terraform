module "security_group_aurora" {
  source = "../../../modules/security-group"

  env     = var.env
  project = var.project

  name   = "aurora"
  vpc_id = data.terraform_remote_state.general.outputs.vpc_id
  ingress_rules = [
    # {
    #   from_port       = 5432
    #   to_port         = 5432
    #   protocol        = "tcp"
    #   security_groups = [module.security_group_worker.security_group_id]
    #   description     = "EC2 Worker"
    # },
    {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [module.security_group_app.security_group_id]
      description     = "App host (frontend + backend)"
    }
    # Bastion rule removed along with the bastion host itself.
  ]
}

module "aurora" {
  source = "../../../modules/aurora-serverless"

  env     = var.env
  project = var.project

  name                    = "main"
  engine_version          = "18.3"
  parameter_group_family  = "aurora-postgresql18"
  database_name           = data.sops_file.secret_enc.data["DB_NAME"]
  master_username         = data.sops_file.secret_enc.data["DB_USERNAME"]
  master_password         = data.sops_file.secret_enc.data["DB_PASSWORD"]
  port                    = 5432
  subnet_ids              = data.terraform_remote_state.general.outputs.subnet_data_id
  security_group_ids      = [module.security_group_aurora.security_group_id]
  kms_key_id              = data.terraform_remote_state.general.outputs.kms_shared_arn
  instance_count          = 1
  min_capacity            = 0.5
  max_capacity            = 4
  backup_retention_period = 7
}
