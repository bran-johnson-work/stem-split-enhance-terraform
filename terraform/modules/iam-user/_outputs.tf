#modules/iam-user/_outputs.tf
output "iam_user_name" {
  value       = aws_iam_user.iam_user.name
  description = "Name of the IAM user (use it to create an access key in the console)"
}

output "iam_user_arn" {
  value       = aws_iam_user.iam_user.arn
  description = "ARN of the IAM user"
}
