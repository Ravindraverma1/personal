module "add-oci-schema" {
  source                    = "./modules/add-oci-schema"
  enable_oci_db             = var.enable_oci_db
  customer                  = var.customer
  env                       = var.env
  aws_region                = var.aws_region
  lambda_subnet_ids         = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  #lambda_security_group_id = aws_security_group.cv.id
  lambda_security_group_ids = local.cv_security_groups
}