resource "aws_lb_listener" "alb_listener" {
  for_each = { for value in var.alb_listeners : value.port => value }

  load_balancer_arn = aws_lb.alb.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = each.value.ssl_policy
  certificate_arn   = each.value.certificate_arn

  dynamic "default_action" {
    for_each = each.value.default_action.type == "redirect" ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = each.value.default_action.redirect.port
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = each.value.default_action.type == "forward" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = each.value.default_action.forward.target_group_arn
    }
  }

  dynamic "default_action" {
    for_each = each.value.default_action.type == "forward_weight" ? [1] : []
    content {
      type = "forward"
      forward {
        dynamic "target_group" {
          for_each = each.value.default_action.target_groups
          content {
            arn    = target_group.value.target_group_arn
            weight = target_group.value.target_group_weight
          }
        }
        dynamic "stickiness" {
          for_each = each.value.default_action.stickiness != {} ? [1] : []
          content {
            duration = each.value.default_action.stickiness.duration
            enabled  = each.value.default_action.stickiness.enabled
          }
        }
      }
    }
  }

  dynamic "default_action" {
    for_each = each.value.default_action.type == "fixed-response" ? [1] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = each.value.default_action.fixed_response.content_type
        status_code  = each.value.default_action.fixed_response.status_code
        message_body = each.value.default_action.fixed_response.message_body != null ? data.template_file.default_action_fixed_response_message_body[each.key].rendered : null
      }
    }
  }

  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      load_balancer_arn,
      default_action
    ]
  }
}

data "template_file" "default_action_fixed_response_message_body" {
  for_each = { for value in var.alb_listeners : value.port => value }
  template = each.value.default_action.fixed_response.message_body.template
  vars     = each.value.default_action.fixed_response.message_body.vars
}
