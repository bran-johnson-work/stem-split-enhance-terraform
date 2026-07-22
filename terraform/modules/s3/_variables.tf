#modules/s3/_variables.tf
#s3-bucket
variable "s3_bucket" {
  description = "All configurations to Provides a S3 bucket resource."
  type = object({
    name                = string
    force_destroy       = optional(bool, true)
    object_lock_enabled = optional(bool, false)
    object_lock_configuration = optional(object({
      rule = object({
        default_retention = object({
          mode  = string # GOVERNANCE or COMPLIANCE
          days  = optional(number, null)
          years = optional(number, null)
        })
      })
    }), null)
    object_ownership = optional(string, "BucketOwnerEnforced") #BucketOwnerPreferred(logging) or ObjectWriter
    sse = optional(object({
      kms_master_key_id = optional(string, null)
      sse_algorithm     = string
    }), null)
    versioning = optional(string, "Suspended")
    logging = optional(object({
      target_bucket_id = string
    }), null)
    cors_rule = optional(list(object({
      allowed_headers = optional(list(string), ["*"])
      allowed_methods = optional(list(string), ["PUT", "POST"])
      allowed_origins = optional(list(string), ["*"])
      expose_headers  = optional(list(string), [])
      max_age_seconds = optional(number, 3000)
    })), [])
    lifecycle_versioning = optional(object({
      status                                         = string
      filter_prefix                                  = optional(string, null)
      noncurrent_version_expiration_days             = optional(number, 90)
      noncurrent_version_transition_days_standard_ia = optional(number, null)
      noncurrent_version_transition_days_glacier     = optional(number, null)
    }), null)
    lifecycle = optional(list(object({
      id                          = string
      status                      = string
      filter_prefix               = optional(string, null)
      expiration_days             = optional(number, null)
      expiration_date             = optional(string, null)
      transition_days_standard_ia = optional(number, null)
      transition_days_glacier     = optional(number, null)
    })), [])
    intelligent_tiering = optional(bool, false)
  })
}


#s3-bucket-policy
variable "s3_bucket_policy" {
  description = "Attaches a policy to an S3 bucket resource."
  default     = null
  type = object({
    template = string
  })
}

#s3-object
variable "s3_objects" {
  description = "List of objects to be created in the S3 bucket."
  default     = []
  type = list(object({
    key = string
    content = optional(object({
      template = string
      vars     = optional(map(string), {})
    }), null)
    source = optional(string, null)
  }))
}

variable "s3_bucket_notification_eventbridge" {
  description = "Enable EventBridge notifications on the S3 bucket"
  type        = bool
  default     = false
}
