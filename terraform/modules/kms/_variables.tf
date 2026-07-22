#modules/kms/_variables.tf
#basic
variable "project" {
  description = "Name of project"
  type        = string
}
variable "env" {
  description = "Name of project environment"
  type        = string
}
variable "region" {
  description = "Region of environment"
  type        = string
}

#kms
variable "name" {
  description = "Name of KMS Custom Managed Key"
  type        = string
}

variable "enable_key_rotation" {
  description = "Specifies whether key rotation is enabled"
  type        = bool
  default     = false
}

#kms-policy
variable "kms_policy" {
  description = "Attaches a policy to an KMS resource."
  default     = null
  type = object({
    template = string
  })
}
