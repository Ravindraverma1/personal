locals {
  # app tier uses these 2 route tables as compared to data tier with optional 3rd
  app_tier_route_tables = [aws_route_table.nat-route1a[0].id, aws_route_table.nat-route1b[0].id]
}

# SST OCI transit gateway share
data "aws_ssm_parameter" "sst_oci_tgw_share_arn" {
  count    = var.enable_oci_db == "true" ? 1 : 0
  provider = aws.sst
  name     = "/sst/oci/tgw_share_arn"
}

data "aws_ec2_transit_gateway" "sst_oci_shared_tgw" {
  count    = var.enable_oci_db == "true" ? 1 : 0
  provider = aws.sst
  filter {
    name   = "tag:Name"
    values = ["sst-oci-tgw-${var.aws_region}"]
  }
}

data "aws_dx_gateway" "dxgw" {
  count    = var.enable_oci_db == "true" ? 1 : 0
  provider = aws.sst
  name     = "sst-oci-dx-gateway-${var.aws_region}"
}

data "aws_ec2_transit_gateway_dx_gateway_attachment" "tgw_dx_gtw_att" {
  count              = var.enable_oci_db == "true" ? 1 : 0
  provider           = aws.sst
  transit_gateway_id = data.aws_ec2_transit_gateway.sst_oci_shared_tgw[0].id
  dx_gateway_id      = data.aws_dx_gateway.dxgw[0].id
}

# creates oci-linked environment transit gateway route table
resource "aws_ec2_transit_gateway_route_table" "sst_oci_env_tgw_rtb" {
  count              = var.enable_oci_db == "true" ? 1 : 0
  provider           = aws.sst
  transit_gateway_id = data.aws_ec2_transit_gateway.sst_oci_shared_tgw[0].id
  tags = {
    customer = var.customer
    env      = var.env
    Name     = "${var.customer}-${var.env}-sst-oci-rtb-${var.aws_region}",
  }
}

# null_resource instead of aws_ram_resource_share_accepter for idempotent sharing of multi-envs on same account principal
resource "null_resource" "sst_oci_tgw_share_accepter" {
  count = var.enable_oci_db == "true" ? 1 : 0
  provisioner "local-exec" {
    command = "scripts/accept-tgw-share-invitation.sh ${var.env_aws_profile} ${data.aws_ssm_parameter.sst_oci_tgw_share_arn[0].value} ${var.aws_region}"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "sst_oci_tgw_vpc_att" {
  count                                           = var.enable_oci_db == "true" ? 1 : 0
  subnet_ids                                      = [aws_subnet.app_a.id, aws_subnet.app_b.id]
  transit_gateway_id                              = data.aws_ec2_transit_gateway.sst_oci_shared_tgw[0].id
  vpc_id                                          = aws_vpc.main.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = true

  tags = {
    customer = var.customer
    env      = var.env
    Name     = "${var.customer}-${var.env}-sst-oci-att-${var.aws_region}"
    Side     = "Creator"
  }
  depends_on = [null_resource.sst_oci_tgw_share_accepter]
}

resource "aws_ec2_transit_gateway_route_table_association" "vpc_oci_tgw_rtb_assoc" {
  count                          = var.enable_oci_db == "true" ? 1 : 0
  provider                       = aws.sst
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.sst_oci_tgw_vpc_att[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.sst_oci_env_tgw_rtb[0].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpc_oci_tgw_rtb_propagation" {
  count                          = var.enable_oci_db == "true" ? 1 : 0
  provider                       = aws.sst
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_dx_gateway_attachment.tgw_dx_gtw_att[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.sst_oci_env_tgw_rtb[0].id
}

# Routes to sst oci transit gateway
resource "aws_route" "sst_oci_tgw_route" {
  count                  = var.enable_oci_db == "true" ? length(local.app_tier_route_tables) : 0
  route_table_id         = local.app_tier_route_tables[count.index]
  destination_cidr_block = var.vcn_cidr
  transit_gateway_id     = data.aws_ec2_transit_gateway.sst_oci_shared_tgw[0].id
  depends_on             = [null_resource.sst_oci_tgw_share_accepter]
}
