resource "aws_iam_role" "cloudwatch_dashboard_update" {
  name = "lambda-cloudwatch-dashboard-update-${var.customer}-${var.env}"

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

resource "aws_iam_policy" "cloudwatch_dashboard_update" {
  name        = "lambda-cloudwatch-dashboard-update-${var.customer}-${var.env}"
  path        = "/"
  description = "Allow cloudwatch-dashboard-update AWS Lambda function to describe EC2 instances and update dashboards"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:log-group:*",
                "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:log-group:*:*:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "*"
        },
    {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeVpnConnections"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutDashboard",
                "cloudwatch:DeleteDashboards"
            ],
            "Resource": [
                "arn:aws:cloudwatch::*:dashboard/*-${var.customer}-${var.env}",
                "arn:aws:cloudwatch::*:dashboard/CloudWatch-Default"
            ]
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "cloudwatch_dashboard_update" {
  role       = aws_iam_role.cloudwatch_dashboard_update.name
  policy_arn = aws_iam_policy.cloudwatch_dashboard_update.arn
}

data "archive_file" "cloudwatch_dashboard_update_zip" {
  type        = "zip"
  output_path = "lambdas/cloudwatch_dashboard_update.zip"
  source_dir  = "lambdas/cloudwatch-dashboard/"
}

resource "aws_lambda_function" "cloudwatch_dashboard_update" {
  filename         = "lambdas/cloudwatch_dashboard_update.zip"
  function_name    = "cloudwatch-dashboard-update-${var.customer}-${var.env}"
  role             = aws_iam_role.cloudwatch_dashboard_update.arn
  handler          = "cloudwatch_dashboard_update.lambda_handler"
  source_code_hash = data.archive_file.cloudwatch_dashboard_update_zip.output_base64sha256
  runtime          = "python3.8"
  timeout          = 10

  environment {
    variables = {
      CUSTOMER                = var.customer
      ENV                     = var.env
      ENABLE_AURORA           = var.enable_aurora
      DB_ID                   = module.db.database_id
      AURORA_DB_ID            = module.aurora.aur_database_id
      EFS_ID                  = aws_efs_file_system.efs_cv.id
      NGINX_FRONT_ALB_FULL_ID = module.nginx_front_alb.this_lb_arn_suffix
      TC_INT_ALB_FULL_ID      = module.tc_int_alb.this_lb_arn_suffix
      VPN_GATEWAY_ID          = element(concat(aws_vpn_gateway.customer_vpn_gateway.*.id, [""]), 0)
    }
  }
}

resource "aws_lambda_permission" "cloudwatch_dashboard_update_cw_exec" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_dashboard_update.arn
  principal     = "events.amazonaws.com"
}

resource "aws_cloudwatch_event_rule" "cloudwatch_dashboard_update_asg" {
  name        = "cloudwatch_dashboard_update_asg-${var.customer}-${var.env}"
  description = "Update CloudWatch dashboards following ASG Instance Launch"

  # custom event pattern to be sent to lambda function
  event_pattern = <<PATTERN
{
  "source": [
    "aws.autoscaling"
  ],
  "detail-type": [
    "EC2 Instance Launch Successful"
  ],
  "detail": {
    "AutoScalingGroupName": [
      "${module.autoscale_group_cv.autoscaling_group_name}",
      "${module.autoscale_group_nginx.autoscaling_group_name}",
      "${module.autoscale_group_tomcat.autoscaling_group_name}"
    ]
  }
}
PATTERN

}

resource "aws_cloudwatch_event_target" "cloudwatch_dashboard_update" {
  rule      = aws_cloudwatch_event_rule.cloudwatch_dashboard_update_asg.name
  target_id = "cloudwatch_dashboard_update-${var.customer}-${var.env}"
  arn       = aws_lambda_function.cloudwatch_dashboard_update.arn
}

