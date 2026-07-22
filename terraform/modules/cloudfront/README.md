# cloudfront
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.55 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.60.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_cache_policy.cloudfront_cache_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_cache_policy) | resource |
| [aws_cloudfront_distribution.cloudfront](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_key_group.cloudfront_key_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_key_group) | resource |
| [aws_cloudfront_origin_access_control.cloudfront_oac](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_cloudfront_public_key.cloudfront_public_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_public_key) | resource |
| [aws_cloudfront_cache_policy.cloudfront_default_cache_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudfront_aliases_domain"></a> [cloudfront\_aliases\_domain](#input\_cloudfront\_aliases\_domain) | Extra CNAMEs (alternate domain names) | `list(string)` | `[]` | no |
| <a name="input_cloudfront_cache_policies"></a> [cloudfront\_cache\_policies](#input\_cloudfront\_cache\_policies) | Creates a CloudFront cache policy. | <pre>list(object({<br>    name        = string<br>    default_ttl = optional(number, null)<br>    max_ttl     = optional(number, null)<br>    min_ttl     = number<br>    brotli      = optional(bool, false)<br>    gzip        = optional(bool, false)<br>    cookies_config = object({<br>      cookie_behavior = string<br>      items           = optional(list(string), [])<br>    })<br>    headers_config = object({<br>      header_behavior = string<br>      items           = optional(list(string), [])<br>    })<br>    query_strings = object({<br>      query_string_behavior = string<br>      items                 = optional(list(string), [])<br>    })<br>  }))</pre> | `[]` | no |
| <a name="input_cloudfront_custom_error_responses"></a> [cloudfront\_custom\_error\_responses](#input\_cloudfront\_custom\_error\_responses) | Variables of custom error responses | <pre>list(object({<br>    error_code            = number<br>    error_caching_min_ttl = number<br>    response_page_path    = optional(string, null)<br>    response_code         = optional(number, null)<br>  }))</pre> | `[]` | no |
| <a name="input_cloudfront_default_cache_behavior"></a> [cloudfront\_default\_cache\_behavior](#input\_cloudfront\_default\_cache\_behavior) | Variables of default cache behaviors | <pre>object({<br>    target_origin_id           = string<br>    viewer_protocol_policy     = optional(string, "redirect-to-https")<br>    allowed_methods            = optional(list(string), ["GET", "HEAD", "OPTIONS"])<br>    cached_methods             = optional(list(string), ["GET", "HEAD"])<br>    compress                   = optional(bool, false)<br>    trusted_key_groups         = optional(bool, false)<br>    cache_policy_id            = string<br>    origin_request_policy_id   = optional(string, null)<br>    response_headers_policy_id = optional(string, null)<br><br>    lambda_function_associations = optional(list(object({<br>      event_type   = string # Valid: viewer-request, origin-request, viewer-response, origin-response<br>      lambda_arn   = string<br>      include_body = optional(bool, false)<br>    })), [])<br>    function_associations = optional(list(object({<br>      event_type   = string<br>      function_arn = string<br>    })), [])<br>  })</pre> | n/a | yes |
| <a name="input_cloudfront_default_cache_policies"></a> [cloudfront\_default\_cache\_policies](#input\_cloudfront\_default\_cache\_policies) | Unique identifier of the cache policy that is attached to the cache behavior | <pre>list(object(<br>    {<br>      name = string<br>    }<br>  ))</pre> | `[]` | no |
| <a name="input_cloudfront_default_root_object"></a> [cloudfront\_default\_root\_object](#input\_cloudfront\_default\_root\_object) | Default root object (index.html) | `string` | `null` | no |
| <a name="input_cloudfront_geo_restriction"></a> [cloudfront\_geo\_restriction](#input\_cloudfront\_geo\_restriction) | Variables of Cloudfront restriction | <pre>object({<br>    restriction_type = optional(string, "none")<br>    locations        = optional(list(string), [])<br>  })</pre> | `{}` | no |
| <a name="input_cloudfront_logging_config_s3_bucket_domain_name"></a> [cloudfront\_logging\_config\_s3\_bucket\_domain\_name](#input\_cloudfront\_logging\_config\_s3\_bucket\_domain\_name) | S3 Bucket log config | `string` | `null` | no |
| <a name="input_cloudfront_name"></a> [cloudfront\_name](#input\_cloudfront\_name) | Name of Cloudfront distribution | `string` | n/a | yes |
| <a name="input_cloudfront_ordered_cache_behaviors"></a> [cloudfront\_ordered\_cache\_behaviors](#input\_cloudfront\_ordered\_cache\_behaviors) | Variables of ordered cache behaviors | <pre>list(object({<br>    target_origin_id           = string<br>    path_pattern               = optional(string, null)<br>    viewer_protocol_policy     = optional(string, "redirect-to-https")<br>    allowed_methods            = optional(list(string), ["GET", "HEAD", "OPTIONS"])<br>    cached_methods             = optional(list(string), ["GET", "HEAD"])<br>    compress                   = optional(bool, false)<br>    trusted_key_groups         = optional(bool, false)<br>    cache_policy_id            = string<br>    origin_request_policy_id   = optional(string, null)<br>    response_headers_policy_id = optional(string, null)<br><br>    lambda_function_associations = optional(list(object({<br>      event_type   = string #Valid: viewer-request, origin-request, viewer-response, origin-response<br>      lambda_arn   = string<br>      include_body = optional(bool, false)<br>    })), [])<br>    function_associations = optional(list(object({<br>      event_type   = string<br>      function_arn = string<br>    })), [])<br>  }))</pre> | `[]` | no |
| <a name="input_cloudfront_origins"></a> [cloudfront\_origins](#input\_cloudfront\_origins) | Variables of cloudfront origin | <pre>list(object({<br>    s3_origin_config = optional(bool, false)<br>    domain_name      = string<br>    origin_id        = string<br>    origin_path      = optional(string, null)<br>    custom_origin_config = optional(object({<br>      http_port                = number<br>      https_port               = number<br>      origin_protocol_policy   = string<br>      origin_ssl_protocols     = list(string)<br>      origin_keepalive_timeout = optional(number, null)<br>      origin_read_timeout      = optional(number, null)<br>    }), null)<br>    custom_header = optional(list(object({<br>      name  = string<br>      value = any<br>    })), [])<br>  }))</pre> | n/a | yes |
| <a name="input_cloudfront_price_class"></a> [cloudfront\_price\_class](#input\_cloudfront\_price\_class) | Price class for this distribution. | `string` | `null` | no |
| <a name="input_cloudfront_public_key"></a> [cloudfront\_public\_key](#input\_cloudfront\_public\_key) | Public key Cloudfront | `string` | `null` | no |
| <a name="input_cloudfront_viewer_certificate"></a> [cloudfront\_viewer\_certificate](#input\_cloudfront\_viewer\_certificate) | Variables of config certificate | <pre>object({<br>    cloudfront_default_certificate = bool<br>    acm_certificate_arn            = optional(string, null)<br>    ssl_support_method             = optional(string, null)<br>    minimum_protocol_version       = optional(string, null)<br>  })</pre> | <pre>{<br>  "cloudfront_default_certificate": true<br>}</pre> | no |
| <a name="input_cloudfront_web_acl_id"></a> [cloudfront\_web\_acl\_id](#input\_cloudfront\_web\_acl\_id) | Unique identifier that specifies the AWS WAF web ACL | `string` | `null` | no |
| <a name="input_env"></a> [env](#input\_env) | ENV of project | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Name of project | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_arn"></a> [cloudfront\_arn](#output\_cloudfront\_arn) | ARN for the distribution. |
| <a name="output_cloudfront_cache_policy_id"></a> [cloudfront\_cache\_policy\_id](#output\_cloudfront\_cache\_policy\_id) | The identifier for the cache policy. |
| <a name="output_cloudfront_default_cache_policy_id"></a> [cloudfront\_default\_cache\_policy\_id](#output\_cloudfront\_default\_cache\_policy\_id) | The identifier for the default cache policy. |
| <a name="output_cloudfront_domain_name"></a> [cloudfront\_domain\_name](#output\_cloudfront\_domain\_name) | DNS domain name of either the S3 bucket, or web site of your custom origin |
| <a name="output_cloudfront_hosted_zone_id"></a> [cloudfront\_hosted\_zone\_id](#output\_cloudfront\_hosted\_zone\_id) | CloudFront Route 53 zone ID that can be used to route an Alias Resource Record Set to |
| <a name="output_cloudfront_id"></a> [cloudfront\_id](#output\_cloudfront\_id) | Identifier for the distribution |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
