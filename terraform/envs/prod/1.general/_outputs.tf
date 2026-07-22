output "vpc_id" {
  value = module.vpc.vpc_id
}
output "subnet_public_id" {
  value = module.vpc.subnet_public_id
}
output "subnet_app_id" {
  value = module.vpc.subnet_app_id
}
output "subnet_data_id" {
  value = module.vpc.subnet_data_id
}
# output "acm_arn" {
#   value = module.acm.acm_cert_arn
# }
# output "acm_cloudfront_arn" {
#   value = module.acm_cloudfront.acm_cert_arn
# }
output "kms_shared_arn" {
  value = module.kms_shared.kms_cmk_arn
}
output "s3_logs_id" {
  value = module.s3_logs.s3_bucket_id
}
output "s3_logs_bucket_domain_name" {
  value = module.s3_logs.s3_bucket_domain_name
}
# output "route53_zone_id" {
#   value = data.aws_route53_zone.selected.zone_id
# }
# Bastion removed for the MVP — the docker-compose host sits in a public subnet and
# is reachable over SSM directly. See git history for bastion.tf if it is needed again.
