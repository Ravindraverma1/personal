module "service-monitoring" {
  source                      = "./modules/service-monitoring"
  account_id                  = data.aws_caller_identity.env_account.account_id
  customer                    = var.customer
  env                         = var.env
  jenkins_env                 = var.jenkins_env
  aws_region                  = var.aws_region
  db_name                     = var.db_name[var.db_parameter_group_family]
  db_port                     = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  db_engine                   = var.db_engine
  db_hostname                 = "db.${var.customer}-${var.env}.axiom"
  lambda_subnet_ids           = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  lambda_security_group_id    = aws_security_group.service_monitoring_lambda_security_group.id
  enable_service_monitoring   = var.enable_service_monitoring
  monitor_workflow_execution  = var.monitor_workflow_execution
  customer_timezone           = var.customer_timezone
  logzio_listener_host        = var.logzio_listener_host
  metrics_logzio_token        = var.metrics_logzio_token
  monitoring_api              = var.monitoring_api
}

