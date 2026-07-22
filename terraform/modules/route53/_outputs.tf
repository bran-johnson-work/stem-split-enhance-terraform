#modules/route53/_outputs.tf
output "route53_zone_ns" {
  description = "A list of name servers in associated (or default) delegation set"
  value       = (var.route53_zone != null && var.route53_zone_id == null) ? aws_route53_zone.route53_zone[0].name_servers : null
}
output "route53_zone_id" {
  description = "The Hosted Zone ID. This can be referenced by zone records"
  value       = (var.route53_zone != null && var.route53_zone_id == null) ? aws_route53_zone.route53_zone[0].zone_id : var.route53_zone_id
}
