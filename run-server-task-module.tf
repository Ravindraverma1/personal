module "run_server_task_module" {
  # TF-UPGRADE-TODO: In Terraform v0.11 and earlier, it was possible to
  # reference a relative module source without a preceding ./, but it is no
  # longer supported in Terraform v0.12.
  #
  # If the below module source is indeed a relative local path, add ./ to the
  # start of the source string. If that is not the case, then leave it as-is
  # and remove this TODO comment.
  source                       = "./modules/run-server-task"
  customer                     = var.customer
  env                          = var.env
  aws_region                   = var.aws_region
  lambda_subnet_ids            = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  lambda_ssh_security_group_id = aws_security_group.lambda_ssh_security_group.id
}

