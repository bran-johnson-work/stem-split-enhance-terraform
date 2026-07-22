resource "aws_security_group" "security_group" {
  name        = "${var.project}-${var.env}-${var.name}-sg"
  vpc_id      = var.vpc_id
  description = "Security group for ${var.project}-${var.env}-${var.name}"

  dynamic "egress" {
    for_each = var.egress_rules

    content {
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      description     = egress.value.description
      cidr_blocks     = egress.value.cidr_blocks
      security_groups = egress.value.security_groups
      prefix_list_ids = egress.value.prefix_list_ids
    }
  }

  dynamic "ingress" {
    for_each = var.ingress_rules

    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      description     = ingress.value.description
      cidr_blocks     = ingress.value.cidr_blocks
      security_groups = ingress.value.security_groups
      prefix_list_ids = ingress.value.prefix_list_ids
    }
  }

  tags = {
    Name = "${var.project}-${var.env}-${var.name}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}
