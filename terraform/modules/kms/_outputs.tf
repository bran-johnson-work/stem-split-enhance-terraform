#modules/kms/_outputs.tf
output "kms_cmk_arn" {
  description = "ARN of AWS KMS Key"
  value       = aws_kms_key.kms_cmk.arn
}
