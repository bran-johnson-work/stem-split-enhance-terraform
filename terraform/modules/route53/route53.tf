resource "aws_route53_zone" "route53_zone" {
  count = (var.route53_zone != null && var.route53_zone_id == null) ? 1 : 0

  name    = var.route53_zone.domain_name
  comment = "DNS for ${var.project} on ${var.env} Environment"

  dynamic "vpc" {
    for_each = var.route53_zone.vpc_id != null ? [1] : []
    content {
      vpc_id = var.route53_zone.vpc_id
    }
  }
}
