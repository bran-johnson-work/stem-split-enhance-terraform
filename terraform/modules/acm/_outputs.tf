#modules/acm/_outputs.tf
output "acm_cert_arn" {
  description = "Amazon Resource Name (ARN) identifying your ACM"
  value       = aws_acm_certificate.acm_cert.arn
}
output "acm_cert_domain_name" {
  description = "Domain name for which the certificate should be issued"
  value       = aws_acm_certificate.acm_cert.domain_name
}
