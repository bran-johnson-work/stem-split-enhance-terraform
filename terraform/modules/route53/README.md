# route53

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.48 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.56.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_route53_record.route53_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.route53_record_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.route53_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env"></a> [env](#input\_env) | Name of project environment | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Name of project | `string` | n/a | yes |
| <a name="input_route53_alias_records"></a> [route53\_alias\_records](#input\_route53\_alias\_records) | All configurations about record for Hostedzone need to use alias | <pre>list(object({<br>    name = string<br>    alias = object({<br>      dns_name = string<br>      zone_id  = string<br>    })<br>  }))</pre> | `[]` | no |
| <a name="input_route53_records"></a> [route53\_records](#input\_route53\_records) | All configurations about record for Hostedzone | <pre>list(object({<br>    name    = string<br>    type    = string<br>    ttl     = optional(number, 300)<br>    records = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_route53_zone"></a> [route53\_zone](#input\_route53\_zone) | All configurations about Route53 Hosted Zone | <pre>object({<br>    domain_name = string<br>    vpc_id      = optional(string, null)<br>  })</pre> | `null` | no |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | The Hosted Zone ID. Using this variable when it already exists and don't need to manage | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_route53_zone_id"></a> [route53\_zone\_id](#output\_route53\_zone\_id) | The Hosted Zone ID. This can be referenced by zone records |
| <a name="output_route53_zone_ns"></a> [route53\_zone\_ns](#output\_route53\_zone\_ns) | A list of name servers in associated (or default) delegation set |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
