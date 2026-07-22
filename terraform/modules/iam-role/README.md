# iam-role

Creae IAM Role
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.48 |
| <a name="requirement_template"></a> [template](#requirement\_template) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.56.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.iam_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.iam_custom_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.iam_default_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assume_role_policy"></a> [assume\_role\_policy](#input\_assume\_role\_policy) | Assume role policy of IAM Role | `string` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | Name of project environment | `string` | n/a | yes |
| <a name="input_iam_custom_policy"></a> [iam\_custom\_policy](#input\_iam\_custom\_policy) | Custom Policy of IAM Role | <pre>object({<br>    template = optional(string, null)<br>  })</pre> | `null` | no |
| <a name="input_iam_default_policy_arn"></a> [iam\_default\_policy\_arn](#input\_iam\_default\_policy\_arn) | ARN of IAM Default Policies managed by AWS | `list(string)` | `[]` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | Create IAM Instance Profile for IAM Role | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of IAM Role/IAM Policy/IAM Instance Profile | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Name of project | `string` | n/a | yes |
| <a name="input_service"></a> [service](#input\_service) | Name of AWS Service using this IAM Role | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_instance_profile_arn"></a> [iam\_instance\_profile\_arn](#output\_iam\_instance\_profile\_arn) | ARN of Instance profile when enable this option |
| <a name="output_iam_instance_profile_id"></a> [iam\_instance\_profile\_id](#output\_iam\_instance\_profile\_id) | ID of Instance profile when enable this option |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of IAM Role |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
