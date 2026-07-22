#modules/cloudfront/_variables.tf
#basic
variable "env" {
  description = "ENV of project"
  type        = string
}
variable "project" {
  description = "Name of project"
  type        = string
}

#cloudfront-cache-policy
variable "cloudfront_cache_policies" {
  description = "Creates a CloudFront cache policy."
  default     = []
  type = list(object({
    name        = string
    default_ttl = optional(number, null)
    max_ttl     = optional(number, null)
    min_ttl     = number
    brotli      = optional(bool, false)
    gzip        = optional(bool, false)
    cookies_config = object({
      cookie_behavior = string
      items           = optional(list(string), [])
    })
    headers_config = object({
      header_behavior = string
      items           = optional(list(string), [])
    })
    query_strings = object({
      query_string_behavior = string
      items                 = optional(list(string), [])
    })
  }))
}
variable "cloudfront_default_cache_policies" {
  default     = []
  description = "Unique identifier of the cache policy that is attached to the cache behavior"
  type = list(object(
    {
      name = string
    }
  ))
}

variable "cloudfront_default_origin_request_policies" {
  default     = []
  description = "Unique identifier of the origin request policy that is attached to the cache behavior"
  type = list(object(
    {
      name = string
    }
  ))
}

variable "cloudfront_default_response_headers_policies" {
  default     = []
  description = "Unique identifier of the response headers policy that is attached to the cache behavior"
  type = list(object(
    {
      name = string
    }
  ))
}

#cloudfront-public-key
variable "cloudfront_public_key" {
  description = "Public key Cloudfront"
  default     = null
  type        = string
}

#cloudfront
variable "cloudfront_name" {
  description = "Name of Cloudfront distribution"
  type        = string
}
variable "cloudfront_price_class" {
  description = "Price class for this distribution."
  default     = null #Valid: PriceClass_All, PriceClass_200, PriceClass_100
  type        = string
}
variable "cloudfront_default_root_object" {
  description = "Default root object (index.html)"
  default     = null
  type        = string
}
variable "cloudfront_aliases_domain" {
  description = "Extra CNAMEs (alternate domain names)"
  default     = []
  type        = list(string)
}
variable "cloudfront_web_acl_id" {
  description = "Unique identifier that specifies the AWS WAF web ACL"
  default     = null
  type        = string
}
variable "cloudfront_logging_config_s3_bucket_domain_name" {
  description = "S3 Bucket log config"
  default     = null
  type        = string
}
variable "cloudfront_viewer_certificate" {
  description = "Variables of config certificate"
  default = {
    cloudfront_default_certificate = true
  }
  type = object({
    cloudfront_default_certificate = bool
    acm_certificate_arn            = optional(string, null)
    ssl_support_method             = optional(string, null)
    minimum_protocol_version       = optional(string, null)
  })
}
variable "cloudfront_geo_restriction" {
  description = "Variables of Cloudfront restriction"
  default     = {}
  type = object({
    restriction_type = optional(string, "none")
    locations        = optional(list(string), [])
  })
}
variable "cloudfront_origins" {
  description = "Variables of cloudfront origin"
  type = list(object({
    s3_origin_config = optional(bool, false)
    domain_name      = string
    origin_id        = string
    origin_path      = optional(string, null)
    custom_origin_config = optional(object({
      http_port                = number
      https_port               = number
      origin_protocol_policy   = string
      origin_ssl_protocols     = list(string)
      origin_keepalive_timeout = optional(number, null)
      origin_read_timeout      = optional(number, null)
    }), null)
    custom_header = optional(list(object({
      name  = string
      value = any
    })), [])
  }))
}
variable "cloudfront_ordered_cache_behaviors" {
  description = "Variables of ordered cache behaviors"
  default     = []
  type = list(object({
    target_origin_id           = string
    path_pattern               = optional(string, null)
    viewer_protocol_policy     = optional(string, "redirect-to-https")
    allowed_methods            = optional(list(string), ["GET", "HEAD", "OPTIONS"])
    cached_methods             = optional(list(string), ["GET", "HEAD"])
    compress                   = optional(bool, false)
    trusted_key_groups         = optional(bool, false)
    cache_policy_id            = string
    origin_request_policy_id   = optional(string, null)
    response_headers_policy_id = optional(string, null)

    lambda_function_associations = optional(list(object({
      event_type   = string #Valid: viewer-request, origin-request, viewer-response, origin-response
      lambda_arn   = string
      include_body = optional(bool, false)
    })), [])
    function_associations = optional(list(object({
      event_type   = string
      function_arn = string
    })), [])
  }))
}
variable "cloudfront_default_cache_behavior" {
  description = "Variables of default cache behaviors"
  type = object({
    target_origin_id           = string
    viewer_protocol_policy     = optional(string, "redirect-to-https")
    allowed_methods            = optional(list(string), ["GET", "HEAD", "OPTIONS"])
    cached_methods             = optional(list(string), ["GET", "HEAD"])
    compress                   = optional(bool, false)
    trusted_key_groups         = optional(bool, false)
    cache_policy_id            = string
    origin_request_policy_id   = optional(string, null)
    response_headers_policy_id = optional(string, null)

    lambda_function_associations = optional(list(object({
      event_type   = string # Valid: viewer-request, origin-request, viewer-response, origin-response
      lambda_arn   = string
      include_body = optional(bool, false)
    })), [])
    function_associations = optional(list(object({
      event_type   = string
      function_arn = string
    })), [])
  })
}
variable "cloudfront_custom_error_responses" {
  description = "Variables of custom error responses"
  default     = []
  type = list(object({
    error_code            = number
    error_caching_min_ttl = number
    response_page_path    = optional(string, null)
    response_code         = optional(number, null)
  }))
}
