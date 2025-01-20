resource "aws_vpn_gateway" "customer_vpn_gateway" {
  count           = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "false" ? 1 : 0
  vpc_id          = aws_vpc.main.id
  amazon_side_asn = var.aws_asn_side
  tags = {
    customer = var.customer
    env      = var.env
    Name     = "${var.customer}-vpn-gateway"
  }
}

resource "aws_vpn_gateway_route_propagation" "customer_vpn_route_propagation" {
  count          = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "false" ? 1 : 0
  vpn_gateway_id = aws_vpn_gateway.customer_vpn_gateway[0].id
  route_table_id = aws_route_table.ig-route-table.id
}

resource "aws_customer_gateway" "customer_gateway" {
  count      = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "false" ? length(var.vpn_connections) : 0
  bgp_asn    = var.vpn_connections[count.index]["customer_bgp_asn"]
  ip_address = var.vpn_connections[count.index]["customer_vpn_gtw_ip"]
  type       = "ipsec.1"
  tags = {
    customer = var.customer
    env      = var.env
    Name     = "${var.customer}-cust-gateway-${count.index}"
  }
  lifecycle {
    ignore_changes = [
      bgp_asn,
      ip_address,
    ]
  }
}

resource "aws_vpn_connection" "vpn_connection" {
  count               = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "false" ? length(var.vpn_connections) : 0
  vpn_gateway_id      = aws_vpn_gateway.customer_vpn_gateway[0].id
  customer_gateway_id = element(aws_customer_gateway.customer_gateway.*.id, count.index)
  type                = "ipsec.1"
  static_routes_only  = true
  tags = {
    customer = var.customer
    env      = var.env
    Name     = "${var.customer}-vpn-connection-to-customer-${count.index}"
  }
  lifecycle {
    ignore_changes = [customer_gateway_id]
  }
}

# multiple customer_internal_cidr_blocks are not supported and existent manual steps are already applied
# nested lists or maps are not supported in lookup
resource "aws_vpn_connection_route" "customer_office" {
  count = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "false" ? length(var.vpn_connections) : 0
  destination_cidr_block = substr(
    replace(
      replace(
        element(
          split(
            ",",
            var.vpn_connections[count.index]["customer_internal_cidr_block"],
          ),
          0,
        ),
        "'",
        "",
      ),
      "]",
      "",
    ),
    1,
    -1,
  )
  vpn_connection_id = element(aws_vpn_connection.vpn_connection.*.id, count.index)
  lifecycle {
    ignore_changes = [
      destination_cidr_block,
      vpn_connection_id,
    ]
  }
}

