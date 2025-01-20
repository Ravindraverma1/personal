module "iac_tests_module" {
  source                   = "./modules/iac-tests"
  customer                 = var.customer
  env                      = var.env
  aws_region               = var.aws_region
  axcloud_domain           = var.axcloud_domain
  lambda_subnet_ids        = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  lambda_security_group_id = aws_security_group.lambda_security_group.id
  cv_version               = var.cv_version
  enable_env_health_check  = var.enable_env_health_check
}

