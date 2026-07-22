resource "aws_subnet" "subnet_data" {
  count = var.data_cidrs != null ? length(var.data_cidrs) : 0

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.data_cidrs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project}-${var.env}-subnet-data-${substr(data.aws_availability_zones.available.names[count.index], -2, -1)}"
  }
}

resource "aws_route_table" "route_data" {
  count = var.data_cidrs != null ? (var.only_one_nat_gateway == true ? 1 : length(var.data_cidrs)) : 0

  vpc_id = aws_vpc.vpc.id

  # See the matching note on aws_route_table.route_app. Aurora is a managed service
  # and needs no outbound internet, so dropping this route is safe for the data tier.
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
    }
  }

  tags = {
    Name = "${var.project}-${var.env}-route-data-${substr(data.aws_availability_zones.available.names[count.index], -2, -1)}"
  }
}

resource "aws_route_table_association" "data" {
  count = var.data_cidrs != null ? length(aws_subnet.subnet_data) : 0

  subnet_id      = aws_subnet.subnet_data[count.index].id
  route_table_id = var.only_one_nat_gateway == true ? aws_route_table.route_data[0].id : aws_route_table.route_data[count.index].id
}
