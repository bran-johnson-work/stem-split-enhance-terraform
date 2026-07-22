## Create ACM wildcard
resource "aws_acm_certificate" "acm_cert" {
  domain_name               = var.acm_domain
  subject_alternative_names = ["*.${var.acm_domain}"]
  validation_method         = "DNS"

  tags = {
    Name = var.acm_domain
  }

  lifecycle {
    create_before_destroy = true
  }
}

## DNS validation for ACM wildcard
# Add DNS to route53
resource "aws_route53_record" "record_validation" {
  for_each = (
    var.record_validation == true ?
    { for dvo in aws_acm_certificate.acm_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    } } : {}
  )


  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = "300"
  zone_id = var.route53_zone_id

  allow_overwrite = true
}
