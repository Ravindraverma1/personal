module "deploy_cv_service_module" {
  source                   = "./modules/deploy-cv-service"
  customer                 = var.customer
  env                      = var.env
  axcloud_domain           = var.axcloud_domain
  cv_version               = var.cv_version
  aws_region               = var.aws_region
  db_name                  = var.db_name[var.db_parameter_group_family]
  db_port                  = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  db_engine                = var.db_engine
  cv_user_schema           = var.cv_user_schema[var.db_parameter_group_family]
  lambda_subnet_ids        = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  lambda_security_group_id = aws_security_group.lambda_security_group.id
  db_ssl_enabled           = local.db_ssl_enabled[var.db_parameter_group_family]
  db_server_dn             = var.db_server_dn
  db_host                  = module.db.database_endpoint
  db_host_rs               = module.redshift.this_redshift_cluster_hostname
  db_name_rs               = var.cluster_database_name
  db_port_rs               = var.cluster_port
  aurora_enabled           = var.enable_aurora
  aurora_db_host           = module.aurora.aurora_instance_endpoint
  db_partitioning_enabled  = var.enable_aurora == "true" ? (tonumber(var.aurora_db_engine_version) >= "12.4" ? "true" : "false") : var.partitioning_enabled[var.db_parameter_group_family]
}

module "call_restapi_module" {
  source                   = "./modules/call-restapi"
  customer                 = var.customer
  env                      = var.env
  axcloud_domain           = var.axcloud_domain
  cv_version               = var.cv_version
  aws_region               = var.aws_region
  lambda_subnet_ids        = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  lambda_security_group_id = aws_security_group.lambda_security_group.id
}

