resource "aws_secretsmanager_secret" "secretsmanager_secret" {
  name                    = "/${var.env}/${var.secret.name}"
  description             = "This is a secret used for ${var.secret.name} configuration"
  kms_key_id              = var.secret.kms_key_id
  recovery_window_in_days = var.secret.recovery_window_in_days
  tags = {
    Name = "${var.project}-${var.env}-${var.secret.name}-secret"
  }
  force_overwrite_replica_secret = var.secret.force_overwrite_replica_secret
  dynamic "replica" {
    for_each = var.secret.replica != null ? var.secret.replica : []
    content {
      region     = replica.value.region
      kms_key_id = replica.value.kms_key_id
    }
  }
}

resource "aws_secretsmanager_secret_version" "secretsmanager_secret_version" {
  secret_id     = aws_secretsmanager_secret.secretsmanager_secret.id
  secret_string = jsonencode(var.secret.secret_string)
}

resource "aws_secretsmanager_secret_policy" "secretsmanager_secret_policy" {
  count      = var.secret.policy != null ? 1 : 0
  secret_arn = aws_secretsmanager_secret.secretsmanager_secret.arn
  policy     = var.secret.policy
}

resource "aws_secretsmanager_secret_rotation" "secretsmanager_secret_rotation" {
  count               = var.secret.secret_rotation != null ? 1 : 0
  secret_id           = aws_secretsmanager_secret.secretsmanager_secret.id
  rotation_lambda_arn = var.secret.secret_rotation.rotation_lambda_arn
  rotation_rules {
    automatically_after_days = var.secret.secret_rotation.rotation_rules.automatically_after_days
  }
}
