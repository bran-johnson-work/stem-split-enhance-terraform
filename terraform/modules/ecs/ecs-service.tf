resource "aws_ecs_service" "ecs_service" {
  for_each = { for value in var.ecs_services : value.name => value }

  name                   = "${var.project}-${var.env}-${each.value.name}-ecs-service"
  cluster                = var.ecs_cluster_name != null ? aws_ecs_cluster.ecs_cluster[0].id : var.ecs_cluster_id
  task_definition        = each.value.task_definition_arn
  desired_count          = each.value.desired_count
  launch_type            = "FARGATE"
  platform_version       = each.value.platform_version
  force_new_deployment   = false
  enable_execute_command = true

  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent
  deployment_maximum_percent         = each.value.deployment_maximum_percent

  network_configuration {
    assign_public_ip = false
    security_groups  = each.value.security_group_ids
    subnets          = each.value.subnet_ids
  }

  deployment_controller {
    type = each.value.deployment_controller
  }

  dynamic "load_balancer" {
    for_each = each.value.load_balancer != null ? [each.value.load_balancer] : []
    content {
      target_group_arn = each.value.load_balancer.target_group_arn
      container_name   = each.value.load_balancer.container_name
      container_port   = each.value.load_balancer.container_port
    }
  }
  health_check_grace_period_seconds = each.value.load_balancer != null ? each.value.load_balancer.health_check_grace_period_seconds : null

  lifecycle {
    ignore_changes = [
      load_balancer,
      desired_count,
      task_definition
    ]
  }
}
