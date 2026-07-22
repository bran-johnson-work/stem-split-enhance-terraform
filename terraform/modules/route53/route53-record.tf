# Create record
resource "aws_route53_record" "route53_record_alias" {
  for_each = { for value in var.route53_alias_records : value.name => value }

  zone_id = (var.route53_zone != null && var.route53_zone_id == null) ? aws_route53_zone.route53_zone[0].zone_id : var.route53_zone_id
  name    = each.value.name
  type    = "A"

  alias {
    name                   = each.value.alias.dns_name
    zone_id                = each.value.alias.zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "route53_record" {
  for_each = { for value in var.route53_records : value.name => value }

  zone_id = (var.route53_zone != null && var.route53_zone_id == null) ? aws_route53_zone.route53_zone[0].zone_id : var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records
}
