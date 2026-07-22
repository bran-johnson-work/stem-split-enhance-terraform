#modules/iam-role/_variables.tf
#basic
variable "env" {
  description = "Name of project environment"
  type        = string
}
variable "project" {
  description = "Name of project"
  type        = string
}
variable "service" {
  description = "Name of AWS Service using this IAM Role"
  type        = string
}

#iam-role
variable "name" {
  description = "Name of IAM Role/IAM Policy/IAM Instance Profile"
  type        = string
}

variable "assume_role_policy" {
  description = "Assume role policy of IAM Role"
  type        = string
}

variable "iam_default_policy_arn" {
  description = "ARN of IAM Default Policies managed by AWS"
  type        = list(string)
  default     = []
}

variable "iam_custom_policy" {
  description = "Custom Policy of IAM Role"
  default     = null
  type = object({
    template = optional(string, null)
  })
}
variable "iam_instance_profile" {
  description = "Create IAM Instance Profile for IAM Role"
  type        = bool
  default     = false
}
