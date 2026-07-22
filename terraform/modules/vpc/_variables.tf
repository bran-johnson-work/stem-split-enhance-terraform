#modules/vpc/_variables.tf
#basic
variable "env" {
  description = "Name of project environment"
  type        = string
}
variable "project" {
  description = "Name of project"
  type        = string
}
variable "region" {
  description = "Region of environment"
  type        = string
}

#vpc
variable "vpc_cidr" {
  description = "CIDR of VPC"
  type        = string
}

#subnet
variable "app_cidrs" {
  description = "A list of app subnets CIDRs inside the VPC"
  type        = list(string)
  default     = null #Default: Don't have app subnet
}
variable "public_cidrs" {
  description = "A list of public subnets CIDRs inside the VPC"
  type        = list(string)
}
variable "data_cidrs" {
  description = "A list of data subnets CIDRs inside the VPC"
  type        = list(string)
  default     = null #Default: Don't have data subnet
}
variable "only_one_nat_gateway" {
  description = "Choose to create only one NAT Gateway for all private subnets or multiple NAT Gateways by AZ number"
  type        = bool
  default     = true #Default: Using only one NAT Gateway for all private subnets
}
variable "enable_nat_gateway" {
  description = "Create NAT Gateways and the 0.0.0.0/0 routes for the app/data subnets. Set false to leave those subnets with no outbound internet access (route tables and subnets are still created)."
  type        = bool
  default     = true #Default: private subnets get outbound internet via NAT
}
