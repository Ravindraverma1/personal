data "aws_availability_zones" "available" {
}

resource "aws_vpc" "main" {
  cidr_block           = "${var.internal_cidr_start1}.0/23"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-vpc"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

# Route Table Associations
# public subnets
resource "aws_route_table_association" "rtba_front_a" {
  subnet_id      = aws_subnet.front_a.id
  route_table_id = aws_route_table.ig-route-table.id
}

resource "aws_route_table_association" "rtba_front_b" {
  subnet_id      = aws_subnet.front_b.id
  route_table_id = aws_route_table.ig-route-table.id
}

resource "aws_route_table_association" "rtba_front_gateway_a" {
  subnet_id      = aws_subnet.front_gateway_a.id
  route_table_id = aws_route_table.ig-route-table.id
}

resource "aws_route_table_association" "rtba_front_gateway_b" {
  subnet_id      = aws_subnet.front_gateway_b.id
  route_table_id = aws_route_table.ig-route-table.id
}

resource "aws_route_table_association" "rtba_app_a" {
  subnet_id      = aws_subnet.app_a.id
  route_table_id = aws_route_table.nat-route1a[0].id
}

resource "aws_route_table_association" "rtba_app_b" {
  subnet_id      = aws_subnet.app_b.id
  route_table_id = aws_route_table.nat-route1b[0].id
}

resource "aws_route_table_association" "rtba_data_a" {
  subnet_id      = aws_subnet.data_a.id
  route_table_id = aws_route_table.nat-route1a[0].id
}

resource "aws_route_table_association" "rtba_data_b" {
  subnet_id      = aws_subnet.data_b.id
  route_table_id = aws_route_table.nat-route1b[0].id
}

resource "aws_route_table_association" "rtba_data_c" {
  count          = var.use_2az == "1" ? 0 : 1
  subnet_id      = aws_subnet.data_c[0].id
  route_table_id = aws_route_table.nat-route1c[0].id
}

# Internet and NAT Gateways
resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-internet_gw"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_nat_gateway" "nat_gw1a" {
  allocation_id = aws_eip.nateip1a.id
  subnet_id     = aws_subnet.front_gateway_a.id
  depends_on    = [aws_internet_gateway.internet_gw]
}
