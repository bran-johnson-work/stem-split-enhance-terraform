#modules/acm/_variables.tf
#acm
variable "acm_domain" {
  description = "Domain need to create ACM"
  type        = string
}
variable "route53_zone_id" {
  description = "ID of route53 hosted zone validate ACM"
  type        = string
  default     = null
}
variable "record_validation" {
  description = "Validation to create ACM DNS in Route53"
  type        = bool
  default     = true
}
