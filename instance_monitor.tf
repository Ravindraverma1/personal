#
# Cloudwatch Alarm when Instance created
#

resource "aws_iam_role_policy" "cw_alarms_policy" {
  name = aws_iam_role.cw_alarms_lambda_iam.name
  role = aws_iam_role.cw_alarms_lambda_iam.id

  policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [{
			"Effect": "Allow",
			"Action": [
				"logs:CreateLogStream",
				"logs:PutLogEvents"
			],
			"Resource": "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:log-group:*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"logs:CreateLogGroup",
				"ec2:DescribeInstances",
				"ec2:DescribeInstanceStatus",
				"cloudwatch:PutMetricAlarm",
				"cloudwatch:PutDashboard",
				"cloudwatch:DeleteDashboards",
				"cloudwatch:EnableAlarmActions",
				"cloudwatch:DeleteAlarms",
				"cloudwatch:GetMetricData",
				"cloudwatch:DisableAlarmActions",
				"cloudwatch:ListMetrics",
				"cloudwatch:DescribeAlarms"
			],
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"events:DeleteRule",
				"events:PutTargets",
				"events:DescribeRule",
				"events:PutRule",
				"events:ListRules",
				"events:RemoveTargets",
				"events:ListTargetsByRule"
			],
			"Resource": "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:rule/*"
		}
	]
}
EOF

}

resource "aws_iam_role" "cw_alarms_lambda_iam" {
  name = "cw-alarms-lambda-${var.customer}-${var.env}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

data "archive_file" "cloudwatch_alarm_definition_zip" {
  type        = "zip"
  output_path = "lambdas/cloudwatch_alarm_definition.zip"
  source_file  = "lambdas/cloudwatch_alarm_definition.py"
}

resource "aws_lambda_function" "cloudwatch_alarm_definition" {
  filename         = "lambdas/cloudwatch_alarm_definition.zip"
  function_name    = "cloudwatch_alarm_definition_${var.customer}_${var.env}"
  role             = aws_iam_role.cw_alarms_lambda_iam.arn
  handler          = "cloudwatch_alarm_definition.lambda_handler"
  source_code_hash = data.archive_file.cloudwatch_alarm_definition_zip.output_base64sha256
  runtime          = "python3.8"
  timeout          = "60"

  environment {
    variables = {
      MONITOR_SNS_TOPIC  = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Monitor-Notification-${var.customer}-${var.env}"
      SECURITY_SNS_TOPIC = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Security-Notification-${data.aws_caller_identity.env_account.account_id}"
      CUSTOMER           = var.customer
      ENV                = var.env
    }
  }
}

resource "aws_lambda_permission" "allow_clonfig_instance_incident" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_alarm_definition.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.instances_check.arn
}

resource "aws_cloudwatch_event_rule" "instances_check" {
  name          = "instance-alarm-${var.customer}-${var.env}"
  description   = "Redefine all Instance relevant for CV TOMCAT and Nginx only when new instance wake up"
  event_pattern = <<PATTERN
{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance State-change Notification"
  ],
  "detail": {
    "state": [
      "running"
    ]
  }
}
PATTERN

}

resource "aws_cloudwatch_event_target" "lambda_to_create_alarm" {
  rule      = aws_cloudwatch_event_rule.instances_check.name
  target_id = "cloudwatch_alarm_definition-${var.customer}-${var.env}"
  arn       = aws_lambda_function.cloudwatch_alarm_definition.arn
}

