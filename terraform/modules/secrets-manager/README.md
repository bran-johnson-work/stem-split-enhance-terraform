# Secrets Manager

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.48 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.72.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.secretsmanager_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_policy.secretsmanager_secret_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_policy) | resource |
| [aws_secretsmanager_secret_rotation.secretsmanager_secret_rotation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource |
| [aws_secretsmanager_secret_version.secretsmanager_secret_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env"></a> [env](#input\_env) | Name of project environment | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Name of project | `string` | n/a | yes |
| <a name="input_secret"></a> [secret](#input\_secret) | All configurations to Provides a Secrets Manager resource | <pre>object({<br/>    kms_key_id                     = optional(string, null)<br/>    recovery_window_in_days        = optional(number, 30)<br/>    name                           = string<br/>    secret_string                  = map(string)<br/>    policy                         = optional(string, null)<br/>    force_overwrite_replica_secret = optional(string, false)<br/>    replica = optional(list(object({<br/>      kms_key_id = optional(string, null)<br/>      region     = optional(string, null)<br/>    })))<br/>    secret_rotation = optional(object({<br/>      rotate_immediately  = optional(bool, false)<br/>      rotation_lambda_arn = optional(string, null)<br/>      rotation_rules = object({<br/>        automatically_after_days = optional(number, null)<br/>      })<br/>    }), null)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_secret_arn"></a> [secret\_arn](#output\_secret\_arn) | The ARN of the Secrets Manager secret |
| <a name="output_secret_id"></a> [secret\_id](#output\_secret\_id) | The ID of the Secrets Manager secret |
| <a name="output_secret_string"></a> [secret\_string](#output\_secret\_string) | The string of the Secrets Manager secret |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
