#modules/alb-bg/_variables.tf
#basic
variable "project" {
  description = "Name of project"
  type        = string
}
variable "env" {
  description = "Name of project environment"
  type        = string
}

#alb
variable "type" {
  description = "Name of application type"
  type        = string
}

variable "alb" {
  description = "All configurations to Provides a Load Balancer resource"
  type = object({
    internal           = optional(bool, false)
    security_groups_id = list(string)
    subnets_id         = list(string)
    logs_bucket_id     = string
    logs_bucket_prefix = optional(string, null)
    idle_timeout       = optional(number, 60)
  })
}

variable "alb_target_group" {
  description = "All configurations to Provides a Target Group resources of Load Balancer resource"
  default     = {}
  type = object({
    vpc_id = optional(string, null)
    target_groups = optional(list(object({
      name                 = string
      target_type          = string
      port                 = number
      deregistration_delay = optional(string, 300)
      protocol_version     = optional(string, "HTTP1")
      health_check = object({
        port                = number
        path                = string
        healthy_threshold   = optional(number, 3)
        unhealthy_threshold = optional(number, 3)
        interval            = optional(number, 30)
        timeout             = optional(number, null)
        matcher             = optional(string, "200")
      })
      stickiness = optional(object({
        type            = string
        cookie_duration = optional(number, 1)
        cookie_name     = optional(string, "AWSALB")
        enabled         = optional(bool, true)
        }
      ), null)
    })), [])
  })
}

variable "alb_listeners" {
  description = "All configurations to Provides a Load Balancer Listener resources"
  default     = []
  type = list(object({
    port            = number
    protocol        = string
    ssl_policy      = optional(string, null)
    certificate_arn = optional(string, null)
    default_action = object({
      type = string
      redirect = optional(object({
        port = number
      }), null)
      forward = optional(object({
        target_group_arn = string
      }), null)
      target_groups = optional(list(object({
        target_group_arn    = string
        target_group_weight = number
      })), null)
      stickiness = optional(object({
        enabled  = optional(bool, false)
        duration = optional(number, 1)
      }), {})
      fixed_response = optional(object({
        content_type = optional(string, null)
        status_code  = optional(number, null)
        message_body = optional(object({
          template = optional(string, null)
          vars     = optional(map(any), {})
        }), {})
      }), {})
    })
  }))
}

variable "alb_listener_rules" {
  description = "All configurations to Provides a Load Balancer Listener Rule resources"
  default     = []
  type = list(object({
    listener_arn = string
    priority     = number
    condition = optional(list(object({
      type   = string
      values = list(string)
    })), null)
    condition_http_header = optional(list(object({
      http_header_name = string
      values           = list(string)
    })), null)
    condition_query_string = optional(list(object({
      key   = optional(string, null)
      value = string
    })), null)
    action = object({
      type = string
      forward = optional(object({
        target_group_arn = optional(string, null)
      }), {})
      target_groups = optional(list(object({
        target_group_arn    = string
        target_group_weight = number
      })), null)
      stickiness = optional(object({
        enabled  = optional(bool, false)
        duration = optional(number, 1)
      }), {})
      authentication = optional(string, null)
      fixed_response = optional(object({
        content_type = optional(string, null)
        status_code  = optional(number, null)
        message_body = optional(object({
          template = optional(string, null)
          vars     = optional(map(any), {})
        }), {})
      }), {})
      redirect = optional(object({
        host        = optional(string, null)
        path        = optional(string, null)
        query       = optional(string, null)
        port        = optional(string, null)
        protocol    = optional(string, null)
        status_code = string
      }))
      authenticate_cognito = optional(object({
        authentication_request_extra_params = optional(map(string))
        on_unauthenticated_request          = optional(string, null)
        scope                               = optional(string, null)
        session_cookie_name                 = optional(string, null)
        session_timeout                     = optional(number, null)
        user_pool_arn                       = string
        user_pool_client_id                 = string
        user_pool_domain                    = string
      }))
      authenticate_oidc = optional(object({
        authentication_request_extra_params = optional(map(string))
        authorization_endpoint              = string
        client_id                           = string
        client_secret                       = string
        issuer                              = string
        on_unauthenticated_request          = optional(string, null)
        scope                               = optional(string, null)
        session_cookie_name                 = optional(string, null)
        session_timeout                     = optional(number, null)
        token_endpoint                      = string
        user_info_endpoint                  = string
      }))
    })
  }))
  validation {
    condition = alltrue(flatten([
      for rule in var.alb_listener_rules : [
        rule.condition != null || rule.condition_http_header != null || rule.condition_query_string != null
      ]
    ]))
    error_message = "At least one of 'condition', 'condition_http_header', or 'condition_query_string' must be provided."
  }
}
