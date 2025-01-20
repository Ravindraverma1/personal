/*
#The resources are not supported as of IAC 1.38

data "aws_ec2_transit_gateway" "citrixservices_shared_tgw" {
  count    = var.enable_citrixservices == "true" ? 1 : 0
  provider = aws.citrixservices
  filter {
    name   = "tag:Name"
    values = ["citrixservices-${var.citrixservices_region}-transit_gateway"]
  }
}

data "aws_ec2_transit_gateway_route_table" "citrixservices_def_propagation_tgw_rtb" {
  count    = var.enable_citrixservices == "true" ? 1 : 0
  provider = aws.citrixservices
  filter {
    name   = "default-propagation-route-table"
    values = ["true"]
  }

  filter {
    name   = "transit-gateway-id"
    values = [data.aws_ec2_transit_gateway.citrixservices_shared_tgw[0].id]
  }
}

data "aws_route_table" "citrixservices_ig_rtb" {
  count    = var.enable_citrixservices == "true" ? 1 : 0
  provider = aws.citrixservices
  filter {
    name   = "tag:Name"
    values = ["citrixservices-${var.citrixservices_region}-ig_rtb"]
  }
}

# TGW and citrix services VPC created prior at resource owner side
data "aws_ssm_parameter" "citrixservices_tgw_resource_share_arn" {
  count    = var.enable_citrixservices == "true" ? 1 : 0
  provider = aws.citrixservices
  name     = "/citrixservices-${var.citrixservices_region}/tgw_resource_share_arn"
}

data "aws_ssm_parameter" "citrixservices_vpc_attachment_id" {
  count    = var.enable_citrixservices == "true" ? 1 : 0
  provider = aws.citrixservices
  name     = "/citrixservices-${var.citrixservices_region}/vpc_attachment_id"
}

data "aws_ssm_parameter" "citrixservices_vda_security_group_id" {
  count    = var.enable_citrixservices == "true" ? 1 : 0
  provider = aws.citrixservices
  name     = "/citrixservices-${var.citrixservices_region}/vda_security_group_id"
}

# create vpc attachment with separate association
resource "aws_ec2_transit_gateway_vpc_attachment" "citrixservices_tgw_vpc_att" {
  count                                           = var.enable_citrixservices == "true" ? 1 : 0
  subnet_ids                                      = [aws_subnet.front_a.id, aws_subnet.front_b.id]
  transit_gateway_id                              = data.aws_ec2_transit_gateway.citrixservices_shared_tgw[0].id
  vpc_id                                          = aws_vpc.main.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = true

  tags = {
    customer = var.customer
    env      = var.env
    Name     = "citrixservices-${var.citrixservices_region}-transit_gateway-att_vpc"
    Side     = "Creator"
  }
  depends_on = [null_resource.resource_share_invitation_accepter]
}

# creates shared vpc route table
resource "aws_ec2_transit_gateway_route_table" "attached_env_tgw_rtb" {
  count              = var.enable_citrixservices == "true" ? 1 : 0
  provider           = aws.citrixservices
  transit_gateway_id = data.aws_ec2_transit_gateway.citrixservices_shared_tgw[0].id
}

// now associate it with the vpc attachment
resource "aws_ec2_transit_gateway_route_table_association" "attached_env_rtb_assoc" {
  count                          = var.enable_citrixservices == "true" ? 1 : 0
  provider                       = aws.citrixservices
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.citrixservices_tgw_vpc_att[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.attached_env_tgw_rtb[0].id
}

// with propagation of citrix services VPC
resource "aws_ec2_transit_gateway_route_table_propagation" "attached_env_rtb_prop" {
  count                          = var.enable_citrixservices == "true" ? 1 : 0
  provider                       = aws.citrixservices
  transit_gateway_attachment_id  = data.aws_ssm_parameter.citrixservices_vpc_attachment_id[0].value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.attached_env_tgw_rtb[0].id
}

# accepts tgw resource share at target account (required because no terraform resource in 2.14.0 aws provider)
resource "null_resource" "citrixservices_resource_share_invitation_accepter" {
  # triggers = {
  #   env_aws_profile = var.env_aws_profile
  #   citrixservices_tgw_resource_share_arn = data.aws_ssm_parameter.citrixservices_tgw_resource_share_arn[0].value
  #   citrixservices_tgw_principal_assoc = aws_ram_principal_association.citrixservices_tgw_principal_assoc[0].resource_share_arn

  # }
  count = var.enable_citrixservices == "true" ? 1 : 0
  provisioner "local-exec" {
    command = "scripts/accept-tgw-share-invitation.sh ${var.env_aws_profile} ${data.aws_ssm_parameter.citrixservices_tgw_resource_share_arn[0].value}"
  }

  triggers = {
    principal_assoc = aws_ram_principal_association.citrixservices_tgw_principal_assoc[0].resource_share_arn
  }
}

# Route in VPC ig route table to citrix services transit gateway
resource "aws_route" "citrixservices_tgw_route" {
  count                  = var.enable_citrixservices == "true" ? 1 : 0
  route_table_id         = aws_route_table.ig-route-table.id
  destination_cidr_block = var.citrixservices_cidr_block
  transit_gateway_id     = data.aws_ec2_transit_gateway.citrixservices_shared_tgw[0].id
  depends_on             = [null_resource.citrixservices_resource_share_invitation_accepter]
}

# Route in CitrixServices VPC ig route table to return to regcloud env over private CIDR
resource "aws_route" "citrixservices_tgw_return_route" {
  count                  = var.enable_citrixservices == "true" ? 1 : 0
  provider               = aws.citrixservices
  route_table_id         = data.aws_route_table.citrixservices_ig_rtb[0].id
  destination_cidr_block = aws_vpc.main.cidr_block
  transit_gateway_id     = data.aws_ec2_transit_gateway.citrixservices_shared_tgw[0].id
}

# grant citrix VDA security group to access this customer environment
resource "aws_security_group_rule" "citrix_egress_to_vpc_rule" {
  count             = var.enable_citrixservices == "true" ? 1 : 0
  provider          = aws.citrixservices
  description       = "Allows access ${var.customer}-${var.env}"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = data.aws_ssm_parameter.citrixservices_vda_security_group_id[0].value
  to_port           = 443
  type              = "egress"
  cidr_blocks       = [aws_vpc.main.cidr_block]
}

*/