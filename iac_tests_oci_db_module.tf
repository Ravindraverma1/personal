locals {
  db_identifier       = (var.db_instance_identifier == 1 || var.db_instance_identifier == "1") ? "" : var.db_instance_identifier #1st OCI DB instance has empty identifier to name, the second one has identifier 2
  ssm_db_password     = var.is_prod == "true" ? "db_password_prod${local.db_identifier}" : "db_password${local.db_identifier}"
  ssm_wallet_password = var.is_prod == "true" ? "wallet_password_prod${local.db_identifier}" : "wallet_password${local.db_identifier}"
}

module "iac-tests-oci-db" {
  source              = "./modules/iac-tests-oci-db"
  enable_oci_db       = var.enable_oci_db
  customer            = var.customer
  env                 = var.env
  aws_region          = var.aws_region
  ssm_db_password     = local.ssm_db_password
  ssm_wallet_password = local.ssm_wallet_password
  lambda_subnet_ids   = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  #lambda_security_group_id = aws_security_group.cv.id
  lambda_security_group_ids = local.cv_security_groups
  enable_env_health_check  = var.enable_env_health_check
}
