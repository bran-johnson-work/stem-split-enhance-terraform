# ecs

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.48 |
| <a name="requirement_template"></a> [template](#requirement\_template) | ~> 2.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.59.0 |
| <a name="provider_template"></a> [template](#provider\_template) | 2.2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ecs_cluster.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.ecs_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [template_file.ecs_task_definition](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ecs_cluster_id"></a> [ecs\_cluster\_id](#input\_ecs\_cluster\_id) | Name of the cluster | `string` | `null` | no |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | Name of the cluster | `string` | `null` | no |
| <a name="input_ecs_services"></a> [ecs\_services](#input\_ecs\_services) | All configurations to Provides a ECS Service resource for use with ECS resources | <pre>list(object({<br>    cluster_id                         = optional(string, null)<br>    name                               = string<br>    task_definition_arn                = string<br>    desired_count                      = number<br>    security_group_ids                 = list(string)<br>    subnet_ids                         = list(string)<br>    platform_version                   = optional(string, "1.4.0")<br>    deployment_minimum_healthy_percent = optional(number, 100)<br>    deployment_maximum_percent         = optional(number, 200)<br>    deployment_controller              = optional(string, "ECS")<br>    load_balancer = optional(object({<br>      target_group_arn                  = string<br>      container_name                    = string<br>      container_port                    = number<br>      health_check_grace_period_seconds = optional(number, 120)<br>    }), null)<br>  }))</pre> | n/a | yes |
| <a name="input_ecs_task_definitions"></a> [ecs\_task\_definitions](#input\_ecs\_task\_definitions) | All configurations to Provides a ECS Task Definitions resource for use with ECS resources | <pre>object({<br>    execution_role_arn = string<br>    task_definitions = list(object({<br>      name          = string<br>      total_memory  = number<br>      total_cpu     = number<br>      task_role_arn = string<br>      container_definitions = object({<br>        template = string<br>        vars     = optional(map(any), null)<br>      })<br>      })<br>    )<br>  })</pre> | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | Name of project environment | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Name of project | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | ARN that identifies the cluster |
| <a name="output_ecs_cluster_id"></a> [ecs\_cluster\_id](#output\_ecs\_cluster\_id) | ARN that identifies the cluster |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | Name of the cluster |
| <a name="output_ecs_service_arn"></a> [ecs\_service\_arn](#output\_ecs\_service\_arn) | ARN that identifies the service |
| <a name="output_ecs_service_name"></a> [ecs\_service\_name](#output\_ecs\_service\_name) | Name of the service |
| <a name="output_ecs_task_definition_arn"></a> [ecs\_task\_definition\_arn](#output\_ecs\_task\_definition\_arn) | ARN of the Task Definition |
| <a name="output_ecs_task_definition_arn_without_revision"></a> [ecs\_task\_definition\_arn\_without\_revision](#output\_ecs\_task\_definition\_arn\_without\_revision) | ARN of the Task Definition with the trailing revision removed |
| <a name="output_ecs_task_definition_family"></a> [ecs\_task\_definition\_family](#output\_ecs\_task\_definition\_family) | Family of the Task Definition |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
