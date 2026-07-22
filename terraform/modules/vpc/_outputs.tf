#modules/vpc/_outputs.tf
#VPC
output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "ID of VPC"
}

#Subnet
output "subnet_app_id" {
  value       = var.app_cidrs != null ? aws_subnet.subnet_app[*].id : []
  description = "ID of App Subnet"
}
output "subnet_data_id" {
  value       = var.data_cidrs != null ? aws_subnet.subnet_data[*].id : []
  description = "ID of Data Subnet"
}
output "subnet_public_id" {
  value       = aws_subnet.subnet_public[*].id
  description = "ID of Public Subnet"
}

#Gateway
output "nat_gateway_public_ip" {
  value       = var.app_cidrs != null ? aws_nat_gateway.nat_gateway[*].public_ip : []
  description = "Public IP of NAT Gateway"
}
output "internet_gateway_id" {
  value       = aws_internet_gateway.internet_gateway.id
  description = "ID of Internet Gateway"
}
