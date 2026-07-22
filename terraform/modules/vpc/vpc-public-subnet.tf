resource "aws_subnet" "subnet_public" {
  count = length(var.public_cidrs)

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-${var.env}-subnet-public-${substr(data.aws_availability_zones.available.names[count.index], -2, -1)}"
  }
}

resource "aws_route_table" "route_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${var.project}-${var.env}-route-public"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.subnet_public)

  subnet_id      = aws_subnet.subnet_public[count.index].id
  route_table_id = aws_route_table.route_public.id
}
