# variable "depends_on" {
#   default = []
#   type    = list(string)
# }

module "start_task_module" {
  source                   = "./modules/start-task"
  account_id               = data.aws_caller_identity.env_account.account_id
  customer                 = var.customer
  env                      = var.env
  aws_region               = var.aws_region
  cv_version               = var.cv_version
  axcloud_domain           = var.axcloud_domain
  lambda_subnet_ids        = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  lambda_security_group_id = aws_security_group.lambda_security_group.id
  s3_bucket_id             = data.aws_s3_bucket.trigger-s3-ref.id
}