resource "aws_subnet" "subnet_app" {
  count = var.app_cidrs != null ? length(var.app_cidrs) : 0

  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.app_cidrs[count.index]

  tags = {
    Name = "${var.project}-${var.env}-subnet-app-${substr(data.aws_availability_zones.available.names[count.index], -2, -1)}"
  }
}

resource "aws_route_table" "route_app" {
  count = var.app_cidrs != null ? (var.only_one_nat_gateway == true ? 1 : length(var.app_cidrs)) : 0

  vpc_id = aws_vpc.vpc.id

  # Only routed to the internet when a NAT Gateway exists. With enable_nat_gateway =
  # false the table still exists (subnets associate to it) but carries no default
  # route, so the app subnets keep VPC-local connectivity and nothing else.
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
    }
  }

  tags = {
    Name = "${var.project}-${var.env}-route-app-${substr(data.aws_availability_zones.available.names[count.index], -2, -1)}"
  }
}

resource "aws_main_route_table_association" "main_route" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = var.app_cidrs != null ? aws_route_table.route_app[0].id : aws_route_table.route_public.id
}

resource "aws_route_table_association" "app" {
  count = var.app_cidrs != null ? length(aws_subnet.subnet_app) : 0

  subnet_id      = aws_subnet.subnet_app[count.index].id
  route_table_id = var.only_one_nat_gateway == true ? aws_route_table.route_app[0].id : aws_route_table.route_app[count.index].id
}
