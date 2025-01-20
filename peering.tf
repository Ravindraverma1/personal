data "aws_caller_identity" "peer" {
  provider = aws.sst
}

resource "aws_vpc_peering_connection" "ha-proxy" {
  peer_owner_id = var.sst_account_id
  peer_vpc_id   = var.ha_proxy_vpc
  vpc_id        = aws_vpc.main.id
  peer_region   = var.ha_proxy_region
  auto_accept   = false

  tags = {
    Name = "VPC Peering between ${var.customer}-${var.env} and sst for ha-proxy"
    Side = "Requester"
  }
}

data "aws_caller_identity" "ha-proxy-peer" {
  provider = aws.sst
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "ha-proxy-peer" {
  provider                  = aws.ha-proxy-peer
  vpc_peering_connection_id = aws_vpc_peering_connection.ha-proxy.id
  auto_accept               = true

  tags = {
    Side  = "Accepter"
    Usage = "HaProxy"
  }
}

#############################
#Citrix services VPC peering
#############################

data "aws_caller_identity" "citrixservices" {
  provider = aws.sst
}

data "aws_caller_identity" "citrixservices-peer" {
  provider = aws.sst
}

resource "aws_vpc_peering_connection" "citrixservices" {
  count         = var.enable_citrixservices ? 1 : 0
  peer_owner_id = var.citrixservices_account_id
  peer_vpc_id   = var.citrixservices_vpc_id
  vpc_id        = aws_vpc.main.id
  peer_region   = var.citrixservices_region
  auto_accept   = false #to use true, both VPCs need to be in the same AWS account

  tags = {
    Name = "VPC Peering between ${var.customer}-${var.env} and Citrix services VPC"
    Side = "Requester"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "citrixservices-peer" {
  count                     = var.enable_citrixservices ? 1 : 0
  provider                  = aws.citrixservices
  vpc_peering_connection_id = aws_vpc_peering_connection.citrixservices[0].id
  auto_accept               = true

  tags = {
    Name  = "vpc-peering-to-${var.customer}-${var.env}-vpc"
    Side  = "Accepter"
    Usage = "Citrixservices"
  }
}

resource "aws_route" "citrixservices_acceptors" {
  count                     = var.enable_citrixservices ? length(var.citrixservices_route_table_ids) : 0
  provider                  = aws.citrixservices
  route_table_id            = element(var.citrixservices_route_table_ids, count.index)
  destination_cidr_block    = aws_vpc.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.citrixservices[0].id
}

#Security group rule to allow environment CIDR to Citrix services VDA instance
resource "aws_security_group_rule" "citrixservices-ingress-0" {
  count             = var.enable_citrixservices ? 1 : 0
  provider          = aws.citrixservices
  description       = "${var.customer}-${var.env} environment to Citrix-VDA"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.main.cidr_block]
  security_group_id = var.citrixservices_sg_vda_id
}