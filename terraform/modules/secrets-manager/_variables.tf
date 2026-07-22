#modules/secrets-manager/_variables.tf
#basic
variable "project" {
  description = "Name of project"
  type        = string
}
variable "env" {
  description = "Name of project environment"
  type        = string
}
#secret
variable "secret" {
  description = "All configurations to Provides a Secrets Manager resource"
  type = object({
    kms_key_id                     = optional(string, null)
    recovery_window_in_days        = optional(number, 30)
    name                           = string
    secret_string                  = map(string)
    policy                         = optional(string, null)
    force_overwrite_replica_secret = optional(string, false)
    replica = optional(list(object({
      kms_key_id = optional(string, null)
      region     = optional(string, null)
    })))
    secret_rotation = optional(object({
      rotate_immediately  = optional(bool, false)
      rotation_lambda_arn = optional(string, null)
      rotation_rules = object({
        automatically_after_days = optional(number, null)
      })
    }), null)
  })
}
