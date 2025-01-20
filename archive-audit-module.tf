module "archive_audit_module" {
  source                   = "./modules/archive-audit-task"
  account_id               = data.aws_caller_identity.env_account.account_id
  customer                 = var.customer
  env                      = var.env
  aws_region               = var.aws_region
  cv_version               = var.cv_version
  axcloud_domain           = var.axcloud_domain
  lambda_subnet_ids        = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  lambda_security_group_id = aws_security_group.lambda_security_group.id
  enable_archive_audit     = var.enable_archive_audit
  archive_audit_cron       = var.archive_audit_cron
  customer_timezone        = var.customer_timezone
  project_name             = var.archive_audit_project_name
  branch_name              = var.archive_audit_branch_name
  wf_name                  = var.archive_audit_wf_name
  var_project_name         = var.archive_audit_var_projectname
  var_branch_name          = var.archive_audit_var_branchname
}