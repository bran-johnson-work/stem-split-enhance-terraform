# s3

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.22 |
| <a name="requirement_template"></a> [template](#requirement\_template) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.48.0 |
| <a name="provider_template"></a> [template](#provider\_template) | 2.2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_cors_configuration.s3_bucket_cors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.s3_bucket_lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.s3_bucket_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.s3_bucket_ownership](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.s3_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.s3_bucket_pab](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.s3_bucket_sse](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.s3_bucket_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.s3_object](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [template_file.s3_object](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_s3_bucket"></a> [s3\_bucket](#input\_s3\_bucket) | All configurations to Provides a S3 bucket resource. | <pre>object({<br>    name             = string<br>    object_ownership = optional(string, "BucketOwnerEnforced") #BucketOwnerPreferred(logging) or ObjectWriter<br>    sse = optional(object({<br>      kms_master_key_id = optional(string, null)<br>      sse_algorithm     = string<br>    }), null)<br>    versioning = optional(string, "Suspended")<br>    logging = optional(object({<br>      target_bucket_id = string<br>    }), null)<br>    cors_rule = optional(list(object({<br>      allowed_headers = optional(list(string), ["*"])<br>      allowed_methods = optional(list(string), ["PUT", "POST"])<br>      allowed_origins = optional(list(string), ["*"])<br>      expose_headers  = optional(list(string), [])<br>      max_age_seconds = optional(number, 3000)<br>    })), [])<br>    lifecycle_versioning = optional(object({<br>      status                                         = string<br>      filter_prefix                                  = optional(string, null)<br>      noncurrent_version_expiration_days             = optional(number, 90)<br>      noncurrent_version_transition_days_standard_ia = optional(number, 30)<br>      noncurrent_version_transition_days_glacier     = optional(number, 60)<br>    }), null)<br>    lifecycle = optional(list(object({<br>      id                          = string<br>      status                      = string<br>      filter_prefix               = optional(string, null)<br>      expiration_days             = optional(number, null)<br>      expiration_date             = optional(string, null)<br>      transition_days_standard_ia = optional(number, null)<br>      transition_days_glacier     = optional(number, null)<br>    })), [])<br>  })</pre> | n/a | yes |
| <a name="input_s3_bucket_policy"></a> [s3\_bucket\_policy](#input\_s3\_bucket\_policy) | Attaches a policy to an S3 bucket resource. | <pre>object({<br>    template = string<br>  })</pre> | `null` | no |
| <a name="input_s3_objects"></a> [s3\_objects](#input\_s3\_objects) | List of objects to be created in the S3 bucket. | <pre>list(object({<br>    key = string<br>    content = optional(object({<br>      template = string<br>      vars     = optional(map(string), {})<br>    }), null)<br>    source = optional(string, null)<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | ARN of S3 Bucket |
| <a name="output_s3_bucket_domain_name"></a> [s3\_bucket\_domain\_name](#output\_s3\_bucket\_domain\_name) | Domain name of S3 Bucket |
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | ID of S3 Bucket |
| <a name="output_s3_object_key"></a> [s3\_object\_key](#output\_s3\_object\_key) | Map of keys and IDs of S3 objects |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
