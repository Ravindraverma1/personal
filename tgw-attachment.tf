data "aws_ec2_transit_gateway" "shared_tgw" {
  count    = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "true" ? 1 : 0
  provider = aws.vpnowner
  filter {
    name   = "tag:Name"
    values = ["${var.customer}-transit-gateway"]
  }
}

data "aws_ec2_transit_gateway_route_table" "def_propagation_tgw_rtb" {
  count    = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "true" ? 1 : 0
  provider = aws.vpnowner
  filter {
    name   = "default-propagation-route-table"
    values = ["true"]
  }
}

# TGW and VPNs created prior at resource owner side
data "aws_ssm_parameter" "tgw_resource_share_arn" {
  count    = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "true" ? 1 : 0
  provider = aws.vpnowner
  name     = "/${var.customer}/tgw_resource_share_arn"
}

data "aws_ssm_parameter" "vpn_attachment_ids_param" {
  count    = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "true" ? 1 : 0
  provider = aws.vpnowner
  name     = "/${var.customer}/vpn_attachment_ids"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_vpc_att" {
  count                                           = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "true" ? 1 : 0
  subnet_ids                                      = [aws_subnet.front_a.id, aws_subnet.front_b.id]
  transit_gateway_id                              = data.aws_ec2_transit_gateway.shared_tgw[0].id
  vpc_id                                          = aws_vpc.main.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = true

  tags = {
    customer = var.customer
    env      = var.env
    Name     = "${var.customer}-transit-gateway-att_vpc"
    Side     = "Creator"
  }
  depends_on = [null_resource.resource_share_invitation_accepter]
}

# creates shared vpc route table
resource "aws_ec2_transit_gateway_route_table" "vpc_tgw_rtb" {
  count              = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "true" ? 1 : 0
  provider           = aws.vpnowner
  transit_gateway_id = data.aws_ec2_transit_gateway.shared_tgw[0].id
}

resource "aws_ec2_transit_gateway_route_table_association" "vpc_tgw_rtb_assoc" {
  count                          = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "true" ? 1 : 0
  provider                       = aws.vpnowner
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_vpc_att[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpc_tgw_rtb[0].id
}

resource "null_resource" "vpn_tgw_routes_config" {
  count = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "true" ? length(var.vpn_connections) : 0
  provisioner "local-exec" {
    command = <<EOF
python3 scripts/configure-tgw-vpn-route.py ${var.vpnowner_aws_profile} \
    "${var.vpn_connections[count.index]["customer_internal_cidr_block"]}" \
    ${element(
    split(
      ",",
      data.aws_ssm_parameter.vpn_attachment_ids_param[0].value,
    ),
    count.index,
)} \
    ${aws_ec2_transit_gateway_route_table.vpc_tgw_rtb[0].id} \
    "${var.vpn_connections[count.index]["vpn_static_routes"]}" \
    ${var.aws_region}
EOF

}
triggers = {
  config_handler = var.vpn_connections[count.index]["customer_internal_cidr_block"]
}
depends_on = [
  aws_ec2_transit_gateway_route_table.vpc_tgw_rtb,
  data.aws_ssm_parameter.vpn_attachment_ids_param,
]
}

# accepts tgw resource share at target account (required because no terraform resource in 2.14.0 aws provider)
resource "null_resource" "resource_share_invitation_accepter" {
  count = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "true" && var.env_account_id != var.vpnowner_account_id ? 1 : 0
  provisioner "local-exec" {
    command = "scripts/accept-tgw-share-invitation.sh ${var.env_aws_profile} ${data.aws_ssm_parameter.tgw_resource_share_arn[0].value} ${var.aws_region}"
  }

  triggers = {
    principal_assoc = aws_ram_principal_association.tgw_principal_assoc[0].resource_share_arn
  }
  depends_on = [aws_ram_principal_association.tgw_principal_assoc]
}

# Route in VPC ig route table to transit gateway
# environment is accessible from all VPNs
resource "aws_route" "tgw_route" {
  count                  = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "true" ? length(var.customer_internal_cidr_list) : 0
  route_table_id         = aws_route_table.ig-route-table.id
  destination_cidr_block = element(var.customer_internal_cidr_list, count.index)
  transit_gateway_id     = data.aws_ec2_transit_gateway.shared_tgw[0].id
  depends_on             = [null_resource.resource_share_invitation_accepter]
}

