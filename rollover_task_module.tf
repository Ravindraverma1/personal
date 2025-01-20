module "rollover_task_module" {
  source                   = "./modules/rollover-task"
  customer                 = var.customer
  env                      = var.env
  axcloud_domain           = var.axcloud_domain
  cv_version               = var.cv_version
  aws_region               = var.aws_region
  lambda_subnet_ids        = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  security_group_ids       = [aws_security_group.lambda_security_group.id, aws_security_group.fargate_security_group.id]
}

resource "aws_cloudwatch_event_rule" "cross_acct_rollover_rule" {
  count       = length(distinct(local.cross_acct_principals)) == 1 ? 1 : 0
  name        = "cross_acct_rollover_rule-${var.customer}-${var.env}"
  description = "Sends cross-account rollover event to source environment default event bus"
  event_pattern = <<PATTERN
{
  "account": [
    "${data.aws_caller_identity.env_account.account_id}"
  ],
  "source": [
    "com.axiomsl.cvaas.rollover.${var.customer}-${var.env}"
  ],
  "detail-type": ["rollover_event"]
}
PATTERN

}

resource "aws_cloudwatch_event_target" "cross_acct_rollover_target" {
  count      = length(distinct(local.cross_acct_principals)) == 1 ? 1 : 0
  rule       = aws_cloudwatch_event_rule.cross_acct_rollover_rule[0].name
  target_id  = "cross_acct_rollover_target-${var.customer}-${var.env}"
  arn        = "arn:aws:events:${var.aws_region}:${distinct(local.cross_acct_principals)[0]}:event-bus/default"
  role_arn   = aws_iam_role.cross_acct_event_role[0].arn
}

resource "aws_cloudwatch_event_rule" "rollover_task_rule" {
  name        = "rollover_task_rule-${var.customer}-${var.env}"
  description = "Calls rollover-task lambda to initiate rollover"
  # accepts event from defined accounts
  event_pattern = <<PATTERN
{
  "account": [
    %{~ if length(distinct(local.cross_acct_principals)) > 0 ~}
    "${distinct(local.cross_acct_principals)[0]}",
    %{~ endif ~}
    "${data.aws_caller_identity.env_account.account_id}"
  ],
  "detail": {
    "processOp": [ "export" ],
    "sourceEnvironmentProfile": [ "${var.customer}-${var.env}" ]
  }
}
PATTERN

}

resource "aws_cloudwatch_event_target" "rollover_task_target" {
  rule      = aws_cloudwatch_event_rule.rollover_task_rule.name
  target_id = "rollover_task_target-${var.customer}-${var.env}"
  arn       = module.rollover_task_module.lambda_function_arn
}

# rollover is between 2 AWS accounts
resource "aws_cloudwatch_event_permission" "rollover_event_permission" {
  count        = length(distinct(local.cross_acct_principals)) == 1 ? 1 : 0
  statement_id = "rollover_event_permission-${var.customer}-${var.env}"
  principal    = distinct(local.cross_acct_principals)[0]
}

locals {
  cross_env_principals = concat(var.higher_environments, var.lower_environments)
  cross_acct_principals = [
    for m in local.cross_env_principals:
    lookup(m, "environment_account_id", null)
    if lookup(m, "environment_account_id", null) != data.aws_caller_identity.env_account.account_id
  ]
}
