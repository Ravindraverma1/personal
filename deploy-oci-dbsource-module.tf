module "deploy_oci_dbsource_module" {
  source                   = "./modules/oci-deploy-dbsource"
  customer                 = var.customer
  env                      = var.env
  axcloud_domain           = var.axcloud_domain
  cv_version               = var.cv_version
  aws_region               = var.aws_region
  lambda_subnet_ids        = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  lambda_security_group_id = aws_security_group.lambda_security_group.id
  enable_oci_db            = var.enable_oci_db
}
