#modules/route53/_variables.tf
#basic
variable "project" {
  description = "Name of project"
  type        = string
}
variable "env" {
  description = "Name of project environment"
  type        = string
}

#route53
variable "route53_zone" {
  default     = null
  description = "All configurations about Route53 Hosted Zone"
  type = object({
    domain_name = string
    vpc_id      = optional(string, null)
  })
}

variable "route53_zone_id" {
  description = "The Hosted Zone ID. Using this variable when it already exists and don't need to manage"
  default     = null
  type        = string
}

variable "route53_alias_records" {
  default     = []
  description = "All configurations about record for Hostedzone need to use alias"
  type = list(object({
    name = string
    alias = object({
      dns_name = string
      zone_id  = string
    })
  }))
}

variable "route53_records" {
  default     = []
  description = "All configurations about record for Hostedzone"
  type = list(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    records = list(string)
  }))
}
