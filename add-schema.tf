module "add-schema" {
  source                   = "./modules/add-schema"
  customer                 = var.customer
  env                      = var.env
  axcloud_domain           = var.axcloud_domain
  aws_region               = var.aws_region
  db_name                  = var.db_name[var.db_parameter_group_family]
  db_port                  = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  db_engine                = var.db_engine
  db_hostname              = "db.${var.customer}-${var.env}.axiom"
  db_hostname_rs           = module.redshift.this_redshift_cluster_hostname
  db_name_rs               = var.cluster_database_name
  db_port_rs               = var.cluster_port
  lambda_subnet_ids        = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  lambda_security_group_id = aws_security_group.cv.id
}

