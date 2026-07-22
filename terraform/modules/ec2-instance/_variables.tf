#modules/ec2-instance/_variables.tf
#basic
variable "project" {
  description = "Name of project"
  type        = string
}
variable "env" {
  description = "Name of project environment"
  type        = string
}

#ec2-instance
variable "name" {
  description = "Name of ec2 instance"
  type        = string
}
variable "ami_id" {
  description = "AMI to use for the instance"
  type        = string
}
variable "instance_type" {
  description = "Instance type to use for the instance"
  type        = string
}
variable "key_name" {
  description = "Key name of the Key Pair to use for the instance"
  type        = string
}
variable "security_group_ids" {
  description = "List of security group IDs to associate with ec2 instance"
  type        = list(string)
}
variable "subnet_id" {
  description = "VPC Subnet ID to launch in"
  type        = string
}
variable "iam_instance_profile" {
  description = "IAM Instance Profile to launch the instance with"
  type        = string
  default     = null
}
variable "root_block_device" {
  description = "Configuration block to customize details about the root block device of the instance"
  type = object({
    volume_type = string
    volume_size = number
  })
}
variable "cpu_credits" {
  description = "Credit option for CPU usage"
  type        = string
  default     = "standard"
}
variable "disable_api_termination" {
  description = "Termination Protection usage with ec2 instance"
  type        = bool
  default     = false
}
variable "user_data" {
  description = "User data to provide when launching the instance"
  type        = string
  default     = null
}
variable "monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
  default     = false
}
variable "create_eip" {
  description = "Allocate an Elastic IP and associate it with the instance for a stable public address that survives stop/start"
  type        = bool
  default     = false
}
