resource "aws_rds_cluster" "aurora" {
  cluster_identifier     = "${var.project}-${var.env}-${var.name}-aurora-cluster"
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = var.engine_version
  database_name          = var.database_name
  master_username        = var.master_username
  master_password        = var.master_password
  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = var.security_group_ids
  port                   = var.port
  storage_encrypted      = true
  kms_key_id             = var.kms_key_id

  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  skip_final_snapshot          = true

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.name

  tags = {
    Name = "${var.project}-${var.env}-${var.name}-aurora-cluster"
  }
}

resource "aws_rds_cluster_instance" "aurora" {
  count              = var.instance_count
  identifier         = "${var.project}-${var.env}-${var.name}-aurora-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  db_subnet_group_name = aws_db_subnet_group.aurora.name

  tags = {
    Name = "${var.project}-${var.env}-${var.name}-aurora-instance-${count.index + 1}"
  }
}

resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project}-${var.env}-${var.name}-aurora-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project}-${var.env}-${var.name}-aurora-subnet-group"
  }
}

resource "aws_rds_cluster_parameter_group" "aurora" {
  name   = "${var.project}-${var.env}-${var.name}-aurora-cluster-pg"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = {
    Name = "${var.project}-${var.env}-${var.name}-aurora-cluster-pg"
  }
}
