#modules/ec2-instance/_outputs.tf
output "ec2_instance_id" {
  value       = aws_instance.ec2_instance.id
  description = "ID of the instance"
}

output "private_ip" {
  value       = aws_instance.ec2_instance.private_ip
  description = "Private IP address of the instance"
}

output "public_ip" {
  value       = var.create_eip ? aws_eip.eip[0].public_ip : aws_instance.ec2_instance.public_ip
  description = "Public IP of the instance — the Elastic IP when create_eip is set, otherwise the auto-assigned public IP"
}
