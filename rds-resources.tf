resource "aws_kms_key" "rds" {
  count               = var.enable_byok == "false" ? 1 : 0
  description         = "RDS Customer Master Key for ${var.customer}-${var.env}"
  enable_key_rotation = true

  tags = {
    Name        = "rds-${var.customer}-${var.env}-${var.aws_region}"
    region      = var.business_region[var.aws_region]
    customer    = var.customer
    Environment = var.env
  }
}

resource "aws_kms_alias" "rds-alias" {
  count         = var.enable_byok == "false" ? 1 : 0
  name          = "alias/rds-${var.customer}-${var.env}"
  target_key_id = aws_kms_key.rds[0].key_id
}


resource "aws_db_subnet_group" "default" {
  count       = var.use_2az == "0" ? 1 : 0
  name_prefix = "main"
  subnet_ids  = [aws_subnet.data_a.id, aws_subnet.data_b.id, element(concat(aws_subnet.data_c.*.id, [""]), 0)]
  tags = {
    Name = "RDS DB subnet group"
  }
}

resource "aws_db_subnet_group" "default_2az" {
  count       = var.use_2az == "1" ? 1 : 0
  name_prefix = "main"
  subnet_ids  = [aws_subnet.data_a.id, aws_subnet.data_b.id]
  tags = {
    Name = "RDS DB subnet group"
  }
}

###########################from sg.tf##################################

resource "aws_security_group" "rds-sg" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-${var.db_engine}"
  description = "RDS ${var.db_engine} database security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-${var.db_engine}"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "rds_sg_ingress_1" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds-sg.id
  description              = "Allows inbound traffic from CV server to ${upper(var.db_engine)} database."
  from_port                = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  to_port                  = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cv.id
}

resource "aws_security_group_rule" "rds_sg_ingress_2" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds-sg.id
  description              = "Allows inbound traffic from TOMCAT server to ${upper(var.db_engine)} database."
  from_port                = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  to_port                  = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tomcat.id
}

resource "aws_security_group_rule" "rds_sg_ingress_3" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds-sg.id
  description              = "Allows inbound traffic from to AWS lambda to ${upper(var.db_engine)} database."
  from_port                = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  to_port                  = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db_usage_lambda_rds_security_group.id
}

resource "aws_security_group_rule" "rds_sg_ingress_4" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds-sg.id
  description              = "Allows inbound traffic from service monitoring lambda to ${upper(var.db_engine)} database."
  from_port                = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  to_port                  = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.service_monitoring_lambda_security_group.id
}

