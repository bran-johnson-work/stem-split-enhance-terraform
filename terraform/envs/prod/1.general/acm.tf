# module "acm" {
#   source = "../../../modules/acm"

#   acm_domain      = var.domain_name
#   route53_zone_id = data.aws_route53_zone.selected.zone_id
# }

# module "acm_cloudfront" {
#   source    = "../../../modules/acm"
#   providers = { aws = aws.east }

#   acm_domain        = var.domain_name
#   record_validation = false
# }
