data "aws_caller_identity" "env_account" {
}

resource "aws_cloudwatch_metric_alarm" "unauthz_api" {
  alarm_name          = "Unauthorized-api-call-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnauthorizedApiCalls"
  namespace           = var.metric_namespace
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Unauthorized API call detected"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Security-Notification-${data.aws_caller_identity.env_account.account_id}"]
}

resource "aws_cloudwatch_metric_alarm" "console_without_mfa" {
  alarm_name          = "console-without-mfa-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ConsoleWithoutMFACount"
  namespace           = var.metric_namespace
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Use of the console by an account without MFA has been detected"
}

resource "aws_cloudwatch_metric_alarm" "root_login" {
  alarm_name          = "root-access-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "RootAccessCount"
  namespace           = var.metric_namespace
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Use of the root account has been detected"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Security-Notification-${data.aws_caller_identity.env_account.account_id}"]
}

resource "aws_cloudwatch_metric_alarm" "iam_change" {
  alarm_name          = "iam-changes-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "IamChanges"
  namespace           = var.metric_namespace
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "IAM Resources have been changed"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Security-Notification-${data.aws_caller_identity.env_account.account_id}"]
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail-config-changes" {
  alarm_name          = "cloudtrail-config-changes-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "cloudtrail-config-changes"
  namespace           = var.metric_namespace
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "AWS CloudTrail config Changes"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Security-Notification-${data.aws_caller_identity.env_account.account_id}"]
}

resource "aws_cloudwatch_metric_alarm" "auth_failure" {
  alarm_name          = "auth_failure-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "auth_failure"
  namespace           = var.metric_namespace
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "AWS Management Console authentication failures"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Security-Notification-${data.aws_caller_identity.env_account.account_id}"]
}

resource "aws_cloudwatch_metric_alarm" "cmk_deletion" {
  alarm_name          = "cmk_deletion-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CmkDeletion"
  namespace           = var.metric_namespace
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "CMKs disable or Shedule deletion of customer CMKS"
}

resource "aws_cloudwatch_metric_alarm" "s3_bucket_policy" {
  alarm_name          = "s3_bucket_policy-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "S3BucketPolicy"
  namespace           = var.metric_namespace
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "S3 bucket policy changes"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Security-Notification-${data.aws_caller_identity.env_account.account_id}"]
}

resource "aws_cloudwatch_metric_alarm" "aws_config_policy" {
  alarm_name          = "aws_config_policy-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "AwsConfigChanges"
  namespace           = var.metric_namespace
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "AWS Config changes"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Security-Notification-${data.aws_caller_identity.env_account.account_id}"]
}

resource "aws_cloudwatch_metric_alarm" "sg_changes" {
  alarm_name          = "sg_changes-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SGChanges"
  namespace           = var.metric_namespace
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "SG changes"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Security-Notification-${data.aws_caller_identity.env_account.account_id}"]
}

resource "aws_cloudwatch_metric_alarm" "nacl_changes" {
  alarm_name          = "nacl_changes-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "NACLChanges"
  namespace           = var.metric_namespace
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "NACL changes"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Security-Notification-${data.aws_caller_identity.env_account.account_id}"]
}

resource "aws_cloudwatch_metric_alarm" "netgw_changes" {
  alarm_name          = "netgw_changes-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "NETGWChanges"
  namespace           = var.metric_namespace
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Network Gateway changes"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Security-Notification-${data.aws_caller_identity.env_account.account_id}"]
}

resource "aws_cloudwatch_metric_alarm" "rt_changes" {
  alarm_name          = "rt_changes-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "RTChanges"
  namespace           = var.metric_namespace
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Routing Tables changes"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Security-Notification-${data.aws_caller_identity.env_account.account_id}"]
}

resource "aws_cloudwatch_metric_alarm" "vpc_changes" {
  alarm_name          = "vpc_changes-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "VPCChanges"
  namespace           = var.metric_namespace
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "VPC changes"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Security-Notification-${data.aws_caller_identity.env_account.account_id}"]
}

locals {
  asg_id = [
    module.autoscale_group_cv.autoscaling_group_name,
    module.autoscale_group_nginx.autoscaling_group_name,
    module.autoscale_group_tomcat.autoscaling_group_name,
  ]

  name = [
    "cv",
    "nginx",
    "tomcat",
  ]
}

# ----------------------
# EC2 Count Status
# ----------------------

resource "aws_cloudwatch_metric_alarm" "count_status" {
  count               = length(local.name)
  alarm_name          = "EC2_Count_Status-${local.name[count.index]}-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Status Check Failed"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Security-Notification-${data.aws_caller_identity.env_account.account_id}"]
  dimensions = {
    AutoScalingGroupName = local.asg_id[count.index]
  }
}

# ----------------------
# RDS CPU Usage
# ----------------------

resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization_warning" {
  alarm_name          = "RDS_CPU_Usage-Warning-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "600"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "RDS CPU Usage Warning > 80%"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Monitor-Notification-${var.customer}-${var.env}"]
  dimensions = {
    DBInstanceIdentifier = var.db_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization_critical" {
  alarm_name          = "RDS_CPU_Usage-Critical-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "600"
  statistic           = "Average"
  threshold           = "95"
  alarm_description   = "RDS CPU Usage Warning > 95%"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Monitor-Notification-${var.customer}-${var.env}"]
  dimensions = {
    DBInstanceIdentifier = var.db_id
  }
}

# ----------------------
# RDS DataBase Connections 
# ----------------------

resource "aws_cloudwatch_metric_alarm" "rds_connections_warning" {
  alarm_name          = "RDS_connection-Warning-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "RDS Connection warning > 80 "
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Monitor-Notification-${var.customer}-${var.env}"]
  dimensions = {
    DBInstanceIdentifier = var.db_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections_critical" {
  alarm_name          = "RDS_connection-Critical-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "RDS Connection warning > 100"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Monitor-Notification-${var.customer}-${var.env}"]
  dimensions = {
    DBInstanceIdentifier = var.db_id
  }
}

# -------------------------
# RDS DataBase Disk Usage 
# -------------------------

resource "aws_cloudwatch_metric_alarm" "rds_disk_usage_warning" {
  count               = var.enable_aurora == "true" ? 0 : 1
  alarm_name          = "RDS_disk_usage-Warning-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.db_allocated_storage * 1024 * 1024 * 1024 * 0.2
  alarm_description   = "RDS Disk Usage warning > 80%"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Monitor-Notification-${var.customer}-${var.env}"]
  dimensions = {
    DBInstanceIdentifier = var.db_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_disk_usage_critical" {
  count               = var.enable_aurora == "true" ? 0 : 1
  alarm_name          = "RDS_disk_usage-Critical-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.db_allocated_storage * 1024 * 1024 * 1024 * 0.1
  alarm_description   = "RDS Disk Usage critical > 90%"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Monitor-Notification-${var.customer}-${var.env}"]
  dimensions = {
    DBInstanceIdentifier = var.db_id
  }
}

# -------------------------
# RDS DataBase Memory Usage 
# -------------------------

resource "aws_cloudwatch_metric_alarm" "rds_memory_usage_warning" {
  count               = var.enable_aurora == "true" ? 0 : 1
  alarm_name          = "RDS_memory_usage-Warning-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.shared_buffers * 32000 * 0.2
  alarm_description   = "RDS Memory Usage warning > 80%"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Monitor-Notification-${var.customer}-${var.env}"]
  dimensions = {
    DBInstanceIdentifier = var.db_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_memory_usage_critical" {
  count               = var.enable_aurora == "true" ? 0 : 1
  alarm_name          = "RDS_memory_usage-Critical-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.shared_buffers * 32000 * 0.05
  alarm_description   = "RDS Memory Usage critical > 95%"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Monitor-Notification-${var.customer}-${var.env}"]
  dimensions = {
    DBInstanceIdentifier = var.db_id
  }
}

# ----------------------
# RDS DB Read/Write IOPS
# ----------------------

resource "aws_cloudwatch_metric_alarm" "rds_read_iops" {
  alarm_name          = "RDS_read_iops-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ReadIOPS"
  namespace           = "AWS/RDS"
  period              = "900"
  statistic           = "Average"
  threshold           = "10000"
  alarm_description   = "RDS Read IOPS > 10K"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Monitor-Notification-${var.customer}-${var.env}"]
  dimensions = {
    DBInstanceIdentifier = var.db_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_write_iops" {
  alarm_name          = "RDS_write_iops-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "WriteIOPS"
  namespace           = "AWS/RDS"
  period              = "900"
  statistic           = "Average"
  threshold           = "50000"
  alarm_description   = "RDS Write IOPS > 50K"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Monitor-Notification-${var.customer}-${var.env}"]
  dimensions = {
    DBInstanceIdentifier = var.db_id
  }
}

# ----------------------
# RDS DB Read/Write Latency
# ----------------------

resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  alarm_name          = "RDS_read_latency-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = "900"
  statistic           = "Average"
  threshold           = "0.01"
  alarm_description   = "RDS Read latency"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Monitor-Notification-${var.customer}-${var.env}"]
  dimensions = {
    DBInstanceIdentifier = var.db_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_write_latency" {
  alarm_name          = "RDS_write_latency-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  period              = "900"
  statistic           = "Average"
  threshold           = "0.02"
  alarm_description   = "RDS Write latency"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Monitor-Notification-${var.customer}-${var.env}"]
  dimensions = {
    DBInstanceIdentifier = var.db_id
  }
}

# CloudWatch log group creation
resource "aws_cloudwatch_log_group" "rollover_task_log_group" {
  name              = "/ecs/${aws_ecs_task_definition.rollover_task_def.family}"
  retention_in_days = 0
  kms_key_id        = aws_kms_key.cloudwatch_kms_key.arn

  tags = {
    Name        = "rollover_log_group-${var.customer}-${var.env}-${var.aws_region}"
    region      = var.business_region[var.aws_region]
    customer    = var.customer
    Environment = var.env
  }
}

resource "aws_cloudwatch_metric_alarm" "env_health_check" {
  count               = var.enable_env_health_check == "true" ? 1 : 0
  actions_enabled     = var.enable_env_health_check
  alarm_name          = "Environment-health-check-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "LessThanThreshold"
  metric_name         = var.env_health_check_count_metric
  evaluation_periods  = "1"
  period              = "300"
  threshold           = "1"
  statistic           = "Minimum"
  treat_missing_data  = "breaching"
  namespace           = module.iac_tests_module.aws_lambda_function_name
  alarm_description   = "Environment health check."
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Environment-Health-Notification-${var.customer}-${var.env}"]
  datapoints_to_alarm = "1"
}

resource "aws_cloudwatch_event_target" "env_health_check_scheduler" {
  count     = var.enable_env_health_check == "true" ? 1 : 0
  target_id = "schedule-iac-tests-${var.customer}-${var.env}"
  rule      = aws_cloudwatch_event_rule.env_health_check_scheduler[0].name
  arn       = module.iac_tests_module.aws_lambda_function_arn
  input     = "{\"test_suites\":\"cvaas\"}"
}

resource "aws_cloudwatch_event_rule" "env_health_check_scheduler" {
  count               = var.enable_env_health_check == "true" ? 1 : 0
  name                = "schedule-iac-tests-${var.customer}-${var.env}"
  description         = "schedule iac test for ${var.customer}-${var.env}"
  schedule_expression = var.env_health_check_schedule
  is_enabled          = var.enable_env_health_check
}

resource "aws_lambda_permission" "env_health_check_scheduler" {
  count         = var.enable_env_health_check == "true" ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.iac_tests_module.aws_lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.env_health_check_scheduler[0].arn
}

resource "aws_cloudwatch_log_metric_filter" "env_health_check" {
  count          = var.enable_env_health_check == "true" ? 1 : 0
  name           = var.env_health_check_count_metric
  pattern        = "\"SUCCESS\""
  log_group_name = "/aws/lambda/${module.iac_tests_module.aws_lambda_function_name}"

  metric_transformation {
    name      = var.env_health_check_count_metric
    namespace = module.iac_tests_module.aws_lambda_function_name
    value     = "1"
  }
}

//OCI DB health check alarm
resource "aws_cloudwatch_metric_alarm" "oci_env_health_check" {
  count               = var.enable_oci_db == "true" && var.enable_env_health_check == "true" ? 1 : 0
  actions_enabled     = var.enable_env_health_check
  alarm_name          = "OCI-DB-Environment-health-check-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "LessThanThreshold"
  metric_name         = var.oci_env_health_check_count_metric
  evaluation_periods  = "1"
  period              = "300"
  threshold           = "1"
  statistic           = "Minimum"
  treat_missing_data  = "breaching"
  namespace           = module.iac-tests-oci-db.aws_lambda_function_name
  alarm_description   = "OCI DB Environment health check."
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Environment-Health-Notification-${var.customer}-${var.env}"]
  datapoints_to_alarm = "1"
}

resource "aws_cloudwatch_event_target" "oci_env_health_check_scheduler" {
  count     = var.enable_oci_db == "true" && var.enable_env_health_check == "true" ? 1 : 0
  target_id = "oci-schedule-iac-tests-${var.customer}-${var.env}"
  rule      = aws_cloudwatch_event_rule.oci_env_health_check_scheduler[0].name
  arn       = module.iac-tests-oci-db.aws_lambda_function_arn
  input     = "{\"test_suites\":\"cvaas\"}"
}

resource "aws_cloudwatch_event_rule" "oci_env_health_check_scheduler" {
  count               = var.enable_oci_db == "true" && var.enable_env_health_check == "true" ? 1 : 0
  name                = "oci-schedule-iac-tests-${var.customer}-${var.env}"
  description         = "schedule iac test for OCI DB ${var.customer}-${var.env}"
  schedule_expression = var.env_health_check_schedule
  is_enabled          = var.enable_env_health_check
}

resource "aws_lambda_permission" "oci_env_health_check_scheduler" {
  count         = var.enable_oci_db == "true" && var.enable_env_health_check == "true" ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.iac-tests-oci-db.aws_lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.oci_env_health_check_scheduler[0].arn
}

resource "aws_cloudwatch_log_metric_filter" "oci_env_health_check" {
  count          = var.enable_oci_db == "true" && var.enable_env_health_check == "true" ? 1 : 0
  name           = var.oci_env_health_check_count_metric
  pattern        = "\"SUCCESS\""
  log_group_name = "/aws/lambda/${module.iac-tests-oci-db.aws_lambda_function_name}"

  metric_transformation {
    name      = var.oci_env_health_check_count_metric
    namespace = module.iac-tests-oci-db.aws_lambda_function_name
    value     = "1"
  }
}
