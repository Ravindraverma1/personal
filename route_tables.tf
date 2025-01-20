#  Route Tables
resource "aws_route_table" "ig-route-table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-ig_route_table"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

### private
resource "aws_route_table" "nat-route1a" {
  vpc_id = aws_vpc.main.id
  count  = var.elk_in_use == 1 ? 1 : 0 #"${var.elk_in_use}"
}

resource "aws_route" "route1a_rt1" {
  route_table_id         = aws_route_table.nat-route1a[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw1a.id
}

resource "aws_route" "route1a_rt2" {
  route_table_id            = aws_route_table.nat-route1a[0].id
  destination_cidr_block    = var.ha_proxy_subnet
  vpc_peering_connection_id = aws_vpc_peering_connection.ha-proxy.id
}

resource "aws_route" "route1a_rt3" {
  count                  = var.enable_vpn_access == "true" && var.use_transit_gateway == "true" && var.enable_mvt_access == "true" ? 1 : 0
  route_table_id         = aws_route_table.nat-route1a[0].id
  destination_cidr_block = var.target_cv9_env_vpc_cidr
  transit_gateway_id     = data.aws_ec2_transit_gateway.shared_tgw[0].id
}

resource "aws_route_table" "nat-route1b" {
  vpc_id = aws_vpc.main.id
  count  = var.elk_in_use == 1 ? 1 : 0 #"${var.elk_in_use}"
}

resource "aws_route" "route1b_rt1" {
  route_table_id         = aws_route_table.nat-route1b[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw1a.id
}

resource "aws_route" "route1b_rt2" {
  route_table_id            = aws_route_table.nat-route1b[0].id
  destination_cidr_block    = var.ha_proxy_subnet
  vpc_peering_connection_id = aws_vpc_peering_connection.ha-proxy.id
}

resource "aws_route" "route1b_rt3" {
  count                  = var.enable_vpn_access == "true" && var.use_transit_gateway == "true" && var.enable_mvt_access == "true" ? 1 : 0
  route_table_id         = aws_route_table.nat-route1b[0].id
  destination_cidr_block = var.target_cv9_env_vpc_cidr
  transit_gateway_id     = data.aws_ec2_transit_gateway.shared_tgw[0].id
}

resource "aws_route_table" "nat-route1c" {
  count  = var.use_2az == "1" ? 0 : 1
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "route1c_rt1" {
  count                  = var.use_2az == "1" ? 0 : 1
  route_table_id         = aws_route_table.nat-route1c[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw1a.id
}

resource "aws_route" "route1c_rt2" {
  count                     = var.use_2az == "1" ? 0 : 1
  route_table_id            = aws_route_table.nat-route1c[0].id
  destination_cidr_block    = var.ha_proxy_subnet
  vpc_peering_connection_id = aws_vpc_peering_connection.ha-proxy.id
}

# internet gateway route
resource "aws_route" "ig_route" {
  route_table_id         = aws_route_table.ig-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gw.id
}

resource "aws_route" "citrixservices_route" {
  count                     = var.enable_citrixservices ? 1 : 0
  route_table_id            = aws_route_table.ig-route-table.id
  destination_cidr_block    = var.citrixservices_vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.citrixservices[0].id
}
