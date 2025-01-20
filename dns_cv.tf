# Resources to update CV's DNS record by listening to CV ASG's launch event

resource "aws_iam_role" "dns_update" {
  name = "lambda-dns-update-${var.customer}-${var.env}"

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

resource "aws_iam_policy" "dns_update" {
  name        = "lambda-dns-update-${var.customer}-${var.env}"
  path        = "/"
  description = "Allow dns-update AWS Lambda function to describe EC2 instances and update dashboards"

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
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": "arn:aws:route53:::hostedzone/${aws_route53_zone.internal.zone_id}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "dns_update" {
  role       = aws_iam_role.dns_update.name
  policy_arn = aws_iam_policy.dns_update.arn
}

resource "null_resource" "dns_update_zip" {
  triggers = {
    x = timestamp()
  }

  provisioner "local-exec" {
    command = "cd lambdas && zip -r dns_update.zip dns_update.py"
  }
}

resource "aws_lambda_function" "dns_update" {
  filename                       = "lambdas/dns_update.zip"
  function_name                  = "dns-update-${var.customer}-${var.env}"
  role                           = aws_iam_role.dns_update.arn
  handler                        = "dns_update.lambda_handler"
  runtime                        = "python3.8"
  timeout                        = 10
  reserved_concurrent_executions = 3

  environment {
    variables = {
      CUSTOMER       = var.customer
      ENV            = var.env
      CV_DNS_NAME    = "${aws_route53_record.cv-instance.name}.${aws_route53_zone.internal.name}"
      TC_DNS_NAME    = "${aws_route53_record.tc-instance.name}.${aws_route53_zone.internal.name}"
      NGINX_DNS_NAME = "${aws_route53_record.nginx-instance.name}.${aws_route53_zone.internal.name}"
      HOSTED_ZONE_ID = aws_route53_zone.internal.zone_id
    }
  }

  depends_on = [null_resource.dns_update_zip]
}

resource "aws_lambda_permission" "dns_update_cw_exec" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dns_update.arn
  principal     = "events.amazonaws.com"
}

resource "aws_cloudwatch_event_rule" "dns_update_asg" {
  name        = "dns_update_asg-${var.customer}-${var.env}"
  description = "Update CV,TC,NGINX DNS record following ASG Instance Launch"

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

resource "aws_cloudwatch_event_target" "dns_update" {
  rule      = aws_cloudwatch_event_rule.dns_update_asg.name
  target_id = "dns_update-${var.customer}-${var.env}"
  arn       = aws_lambda_function.dns_update.arn
}

