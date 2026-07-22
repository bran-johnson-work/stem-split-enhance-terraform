#modules/iam-role/_outputs.tf
#iam-role
output "iam_role_arn" {
  value       = aws_iam_role.iam_role.arn
  description = "ARN of IAM Role"
}

#instance-profile
output "iam_instance_profile_id" {
  value       = var.iam_instance_profile == true ? aws_iam_instance_profile.iam_instance_profile[0].id : null
  description = "ID of Instance profile when enable this option"
}

output "iam_instance_profile_arn" {
  value       = var.iam_instance_profile == true ? aws_iam_instance_profile.iam_instance_profile[0].arn : null
  description = "ARN of Instance profile when enable this option"
}
