variable "migration_vpc_cidr" {
  default = "0.0.0.0/0"
}

data "aws_vpc_peering_connection" "migration_peering" {
  count       = var.enable_migration_peering == "true" ? 1 : 0
  peer_vpc_id = aws_vpc.main.id

  filter {
    name   = "tag:Name"
    values = ["${var.aws_region}-${var.customer}-${var.env}-migration-peering"]
  }

  filter {
    name   = "status-code"
    values = ["active"]
  }
}

resource "aws_route" "acceptor_a" {
  count                     = var.enable_migration_peering == "true" ? 1 : 0
  route_table_id            = aws_route_table.nat-route1a[0].id
  destination_cidr_block    = data.aws_vpc_peering_connection.migration_peering[0].cidr_block
  vpc_peering_connection_id = data.aws_vpc_peering_connection.migration_peering[0].id
}

resource "aws_route" "acceptor_b" {
  count                     = var.enable_migration_peering == "true" ? 1 : 0
  route_table_id            = aws_route_table.nat-route1b[0].id
  destination_cidr_block    = data.aws_vpc_peering_connection.migration_peering[0].cidr_block
  vpc_peering_connection_id = data.aws_vpc_peering_connection.migration_peering[0].id
}

resource "aws_route" "acceptor_c" {
  count                     = var.enable_migration_peering == "true" && var.use_2az == "0" ? 1 : 0
  route_table_id            = aws_route_table.nat-route1c[0].id
  destination_cidr_block    = data.aws_vpc_peering_connection.migration_peering[0].cidr_block
  vpc_peering_connection_id = data.aws_vpc_peering_connection.migration_peering[0].id
}

resource "aws_security_group_rule" "db_migration_ingress" {
  count             = var.enable_migration_peering == "true" ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.rds-sg.id
  description       = "Allows inbound traffic from migration vpc to ${upper(var.db_engine)} database."
  from_port         = var.db_ssl_port[var.db_parameter_group_family]
  to_port           = var.db_ssl_port[var.db_parameter_group_family]
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc_peering_connection.migration_peering[0].cidr_block]
}

resource "aws_security_group_rule" "ssh_from_bastion_ingress_2" {
  count             = var.enable_migration_peering == "true" ? 1 : 0
  type              = "ingress"
  description       = "Allows inbound traffic from migration vpc to CVaaS instances"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.ssh_from_bastion.id
  cidr_blocks       = [data.aws_vpc_peering_connection.migration_peering[0].cidr_block]
}

