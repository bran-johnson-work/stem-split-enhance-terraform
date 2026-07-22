#modules/security-group/_variables.tf
#basic
variable "project" {
  description = "Name of project"
  type        = string
}
variable "env" {
  description = "Name of project environment"
  type        = string
}

#security-group
variable "name" {
  description = "Name of security group"
  type        = string
}
variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}
variable "egress_rules" {
  description = "Configuration block for egress rules"
  default = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow all ingress traffic"
    cidr_blocks = ["0.0.0.0/0"]
  }]
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    description     = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
    prefix_list_ids = optional(list(string), [])
  }))
}
variable "ingress_rules" {
  description = "Configuration block for ingress rules"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    description     = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
    prefix_list_ids = optional(list(string), [])
  }))
}
