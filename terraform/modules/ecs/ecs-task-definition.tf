resource "aws_ecs_task_definition" "ecs_task_definition" {
  for_each = { for value in var.ecs_task_definitions.task_definitions : value.name => value }

  family                   = "${var.project}-${var.env}-${each.value.name}-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.ecs_task_definitions.execution_role_arn
  memory                   = each.value.total_memory
  cpu                      = each.value.total_cpu
  task_role_arn            = each.value.task_role_arn
  container_definitions    = data.template_file.ecs_task_definition[each.key].rendered

  tags = {
    Name = "${var.project}-${var.env}-${each.value.name}-task-definition"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = all
  }
}

data "template_file" "ecs_task_definition" {
  for_each = { for value in var.ecs_task_definitions.task_definitions : value.name => value }

  template = file(each.value.container_definitions.template)
  vars     = each.value.container_definitions.vars
}
