resource "aws_lb" "alb" {
  name                       = "${var.project}-${var.env}-${var.type}-alb"
  load_balancer_type         = "application"
  internal                   = var.alb.internal
  drop_invalid_header_fields = false
  enable_deletion_protection = false
  enable_http2               = false
  idle_timeout               = var.alb.idle_timeout

  security_groups = var.alb.security_groups_id
  subnets         = var.alb.subnets_id

  access_logs {
    enabled = true
    bucket  = var.alb.logs_bucket_id
    prefix  = var.alb.logs_bucket_prefix
  }

  tags = {
    Name = "${var.project}-${var.env}-${var.type}-alb"
    Type = var.type
  }
}

resource "aws_lb_target_group" "alb_target_group" {
  for_each = { for value in var.alb_target_group.target_groups : value.name => value }

  vpc_id      = var.alb_target_group.vpc_id
  name        = "${var.project}-${var.env}-${var.type}-alb-${each.value.name}"
  target_type = each.value.target_type

  port                          = each.value.port
  protocol                      = "HTTP"
  protocol_version              = each.value.protocol_version
  proxy_protocol_v2             = false
  deregistration_delay          = each.value.deregistration_delay
  slow_start                    = 0
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled             = true
    port                = each.value.health_check.port
    protocol            = "HTTP"
    path                = each.value.health_check.path
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    interval            = each.value.health_check.interval
    timeout             = each.value.health_check.timeout
    matcher             = each.value.health_check.matcher
  }
  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [1] : []
    content {
      type            = each.value.stickiness.type
      cookie_duration = each.value.stickiness.cookie_duration
      cookie_name     = each.value.stickiness.cookie_name
      enabled         = each.value.stickiness.enabled
    }
  }

  tags = {
    Name = "${var.project}-${var.env}-${var.type}-alb-${each.value.name}-tg"
    Type = var.type
  }
}
