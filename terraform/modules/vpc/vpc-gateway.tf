#NAT GATEWAY for app subnet
resource "aws_eip" "nat_gateway_eip" {
  count = var.enable_nat_gateway && var.app_cidrs != null ? (var.only_one_nat_gateway == true ? 1 : length(var.app_cidrs)) : 0

  domain = "vpc"

  tags = {
    Name = "${var.project}-${var.env}-nat-gateway-eip-${substr(data.aws_availability_zones.available.names[count.index], -2, -1)}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  count = var.enable_nat_gateway && var.app_cidrs != null ? (var.only_one_nat_gateway == true ? 1 : length(var.app_cidrs)) : 0

  allocation_id = aws_eip.nat_gateway_eip[count.index].id
  subnet_id     = aws_subnet.subnet_public[count.index].id

  tags = {
    Name = "${var.project}-${var.env}-nat-gateway-${substr(data.aws_availability_zones.available.names[count.index], -2, -1)}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#INTERNET GATEWAY for public subnet
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project}-${var.env}-internet-gateway"
  }
}

#3. VPC Endpoint
resource "aws_vpc_endpoint" "endpoint" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.s3"

  tags = {
    Name = "${var.project}-${var.env}-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint_route_table_association" "public" {
  route_table_id  = aws_route_table.route_public.id
  vpc_endpoint_id = aws_vpc_endpoint.endpoint.id
}


resource "aws_vpc_endpoint_route_table_association" "app" {
  count = var.app_cidrs != null ? (var.only_one_nat_gateway == true ? 1 : length(var.app_cidrs)) : 0

  route_table_id  = var.only_one_nat_gateway == true ? aws_route_table.route_app[0].id : aws_route_table.route_app[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.endpoint.id
}
