# ecr

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
| [aws_ecr_lifecycle_policy.ecr_lifecycle_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ecr"></a> [ecr](#input\_ecr) | All configuration to Provides an Elastic Container Registry Repository. | <pre>object({<br>    name                 = string<br>    image_tag_mutability = optional(string, "MUTABLE")<br>    scan_on_push         = optional(bool, false)<br>  })</pre> | n/a | yes |
| <a name="input_ecr_lifecycle_policy"></a> [ecr\_lifecycle\_policy](#input\_ecr\_lifecycle\_policy) | Lifecycle policy for ECR repository | `string` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | Name of project environment | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Name of project | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecr_name"></a> [ecr\_name](#output\_ecr\_name) | Name of ECR Repository |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | URL of ECR Repository |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
