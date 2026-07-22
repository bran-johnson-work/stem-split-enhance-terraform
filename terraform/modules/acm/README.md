# acm

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.37 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.40.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.acm_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_route53_record.record_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_domain"></a> [acm\_domain](#input\_acm\_domain) | Domain need to create ACM | `string` | n/a | yes |
| <a name="input_record_validation"></a> [record\_validation](#input\_record\_validation) | Validation to create ACM DNS in Route53 | `bool` | `true` | no |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | ID of route53 hosted zone validate ACM | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acm_cert_arn"></a> [acm\_cert\_arn](#output\_acm\_cert\_arn) | Amazon Resource Name (ARN) identifying your ACM |
| <a name="output_acm_cert_domain_name"></a> [acm\_cert\_domain\_name](#output\_acm\_cert\_domain\_name) | Domain name for which the certificate should be issued |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
