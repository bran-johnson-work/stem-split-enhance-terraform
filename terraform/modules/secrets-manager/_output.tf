#modules/secrets-manager/_outputs.tf
#Secrets Manager
output "secret_arn" {
  description = "The ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.secretsmanager_secret.arn
}

output "secret_id" {
  description = "The ID of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.secretsmanager_secret.id
}

output "secret_string" {
  description = "The string of the Secrets Manager secret"
  value       = aws_secretsmanager_secret_version.secretsmanager_secret_version.secret_string
}
