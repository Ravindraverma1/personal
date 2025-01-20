module "cv_asg_lifecyclehook_lambda" {
  source                   = "./modules/cv-asg-lifecyclehook"
  account_id               = data.aws_caller_identity.env_account.account_id
  customer                 = var.customer
  env                      = var.env
  aws_region               = var.aws_region
  axcloud_domain           = var.axcloud_domain
  lifecycle_hook_name      = aws_autoscaling_lifecycle_hook.cv_asg_launching.name
  lifecycle_transition     = aws_autoscaling_lifecycle_hook.cv_asg_launching.default_result
  autoscaling_group_name   = aws_autoscaling_lifecycle_hook.cv_asg_launching.autoscaling_group_name
  jenkins_env              = var.jenkins_env
}