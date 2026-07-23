#modules/iam-user/_variables.tf
#basic
variable "env" {
  description = "Name of project environment"
  type        = string
}
variable "project" {
  description = "Name of project"
  type        = string
}

#iam-user
variable "name" {
  description = "Name of IAM User / IAM Policy"
  type        = string
}

variable "iam_custom_policy" {
  description = "Inline custom policy for the IAM user"
  default     = null
  type = object({
    template = optional(string, null)
  })
}
