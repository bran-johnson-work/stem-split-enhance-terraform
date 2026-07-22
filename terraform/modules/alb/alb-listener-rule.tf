resource "aws_lb_listener_rule" "alb_listener_rule" {
  for_each = { for value in var.alb_listener_rules : "${value.priority}-${value.action.type}" => value }

  listener_arn = each.value.listener_arn
  priority     = each.value.priority

  dynamic "condition" {
    for_each = each.value.condition != null ? { for condition in each.value.condition : condition.type => condition } : {}
    content {
      dynamic "host_header" {
        for_each = condition.value.type == "host_header" ? [1] : []
        content {
          values = condition.value.values
        }
      }
      dynamic "source_ip" {
        for_each = condition.value.type == "source_ip" ? [1] : []
        content {
          values = condition.value.values
        }
      }
      dynamic "path_pattern" {
        for_each = condition.value.type == "path_pattern" ? [1] : []
        content {
          values = condition.value.values
        }
      }
      dynamic "http_request_method" {
        for_each = condition.value.type == "http_request_method" ? [1] : []
        content {
          values = condition.value.values
        }
      }
    }
  }

  dynamic "condition" { #For http_header
    for_each = each.value.condition_http_header != null ? { for condition in each.value.condition_http_header : condition.http_header_name => condition } : {}
    content {
      http_header {
        http_header_name = condition.value.http_header_name
        values           = condition.value.values
      }
    }
  }

  dynamic "condition" { #For query_string
    for_each = each.value.condition_query_string != null ? { for condition in each.value.condition_query_string : condition.value => condition } : {}
    content {
      query_string {
        key   = condition.value.key
        value = condition.value.value
      }
    }
  }

  dynamic "action" {
    for_each = each.value.action.authentication != null ? [1] : []
    content {
      type = each.value.action.authentication
      dynamic "authenticate_cognito" {
        for_each = each.value.action.authentication == "authenticate-cognito" ? [1] : []
        content {
          authentication_request_extra_params = each.value.action.authenticate_cognito.authentication_request_extra_params
          on_unauthenticated_request          = each.value.action.authenticate_cognito.on_unauthenticated_request
          scope                               = each.value.action.authenticate_cognito.scope
          session_cookie_name                 = each.value.action.authenticate_cognito.session_cookie_name
          session_timeout                     = each.value.action.authenticate_cognito.session_timeout
          user_pool_arn                       = each.value.action.authenticate_cognito.user_pool_arn
          user_pool_client_id                 = each.value.action.authenticate_cognito.user_pool_client_id
          user_pool_domain                    = each.value.action.authenticate_cognito.user_pool_domain
        }
      }
      dynamic "authenticate_oidc" {
        for_each = each.value.action.authentication == "authenticate-oidc" ? [each.value.action.authentication] : []
        content {
          authentication_request_extra_params = each.value.action.authenticate_oidc.authentication_request_extra_params
          authorization_endpoint              = each.value.action.authenticate_oidc.authorization_endpoint
          client_id                           = each.value.action.authenticate_oidc.client_id
          client_secret                       = each.value.action.authenticate_oidc.client_secret
          issuer                              = each.value.action.authenticate_oidc.issuer
          on_unauthenticated_request          = each.value.action.authenticate_oidc.on_unauthenticated_request
          scope                               = each.value.action.authenticate_oidc.scope
          session_cookie_name                 = each.value.action.authenticate_oidc.session_cookie_name
          session_timeout                     = each.value.action.authenticate_oidc.session_timeout
          token_endpoint                      = each.value.action.authenticate_oidc.token_endpoint
          user_info_endpoint                  = each.value.action.authenticate_oidc.user_info_endpoint
        }
      }
    }
  }

  action {
    type             = each.value.action.type
    target_group_arn = each.value.action.forward.target_group_arn #action_type = "forward"

    dynamic "forward" {
      for_each = each.value.action.type == "forward" && each.value.action.target_groups != null ? [1] : []
      content {
        dynamic "target_group" {
          for_each = each.value.action.target_groups
          content {
            arn    = target_group.value.target_group_arn
            weight = target_group.value.target_group_weight
          }
        }
        dynamic "stickiness" {
          for_each = each.value.action.stickiness != {} ? [1] : []
          content {
            duration = each.value.action.stickiness.duration
            enabled  = each.value.action.stickiness.enabled
          }
        }
      }
    }
    dynamic "fixed_response" { #action_type = "fixed-response"
      for_each = each.value.action.type == "fixed-response" ? [1] : []
      content {
        content_type = each.value.action.fixed_response.content_type
        status_code  = each.value.action.fixed_response.status_code
        message_body = each.value.action.fixed_response.message_body != null ? data.template_file.action_fixed_response_message_body[each.key].rendered : null
      }
    }
  }

  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      action
    ]
  }

  tags = {
    "Name" = "${var.project}-${var.env}-alb-${each.value.action.type}-rule"
  }
}

data "template_file" "action_fixed_response_message_body" {
  for_each = { for value in var.alb_listener_rules : "${value.priority}-${value.action.type}" => value }
  template = each.value.action.fixed_response.message_body.template
  vars     = each.value.action.fixed_response.message_body.vars
}
