# KMS CMKs
resource "aws_kms_key" "kms_cmk" {
  description         = "${var.project}-${var.env}-${var.name}"
  is_enabled          = true
  enable_key_rotation = var.enable_key_rotation
}

# KMS CMKs Alias
resource "aws_kms_alias" "kms_cmk_alias" {
  name          = "alias/${var.project}-${var.env}-${var.region}-${var.name}"
  target_key_id = aws_kms_key.kms_cmk.key_id
}

# KMS CMKs policy
resource "aws_kms_key_policy" "example" {
  count = var.kms_policy != null ? 1 : 0

  key_id = aws_kms_key.kms_cmk.id
  policy = var.kms_policy.template
}
