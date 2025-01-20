resource "aws_lambda_function" "sg_incident_lambda" {
  filename         = "lambdas/sg_incident_lambda.zip"
  function_name    = "sg_incident_lambda_${var.customer}-${var.env}"
  role             = "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/sg-incident-lambda-iam"
  handler          = "sg_incident_lambda.lambda_handler"
  source_code_hash = filebase64sha256("lambdas/sg_incident_lambda.zip")
  runtime          = "python3.8"
  timeout          = "120"
}

resource "aws_lambda_permission" "allow_config_sg_incident" {
  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sg_incident_lambda.function_name
  principal     = "config.amazonaws.com"
  depends_on    = [aws_route53_record.tc-internal]
}

resource "aws_config_config_rule" "sg_incident" {
  name = "sg_incident_${var.customer}-${var.env}"

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.sg_incident_lambda.arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }
  }

  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }

  depends_on = [aws_lambda_permission.allow_config_sg_incident]

  input_parameters = <<EOF
{
  "env_id": "${var.customer}-${var.env}",
  "config_bucket": "axiom-${data.aws_caller_identity.env_account.account_id}-config-bucket"
}
EOF

}

resource "null_resource" "sg_template_creator" {
  provisioner "local-exec" {
    command = "python3 scripts/create_sg_template.py ${var.aws_region} axiom-${data.aws_caller_identity.env_account.account_id}-config-bucket ${var.env_aws_profile}"
  }

  depends_on = [aws_config_config_rule.sg_incident]
}

resource "aws_lambda_function" "instance_incident_lambda" {
  filename         = "lambdas/instance_incident_lambda.zip"
  function_name    = "instance_incident_lambda_${var.customer}-${var.env}"
  role             = "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/unauthorized-instance-incident-lambda-iam"
  handler          = "instance_incident_lambda.lambda_handler"
  source_code_hash = filebase64sha256("lambdas/instance_incident_lambda.zip")
  runtime          = "python3.8"
}

resource "aws_lambda_permission" "allow_config_instance_incident" {
  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.instance_incident_lambda.function_name
  principal     = "config.amazonaws.com"
  depends_on    = [aws_route53_record.tc-internal]
}

resource "aws_config_config_rule" "instance_incident" {
  name = "unauthorized_instance_incident_${var.customer}-${var.env}"

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.instance_incident_lambda.arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }
  }

  scope {
    compliance_resource_types = ["AWS::EC2::Instance"]
  }

  depends_on = [aws_lambda_permission.allow_config_instance_incident]
}

####### Add Cloudwatch event rules to run Lambda Function when config rule change status from COMPLIANT to NON_COMPLIANT
resource "aws_cloudwatch_event_rule" "config_rules_non_compliant" {
  name        = "config_rules_non_compliant_${var.customer}-${var.env}"
  description = "Send Email when config rules change status to non_compliant"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.config"
  ],
  "detail-type": [
    "Config Rules Compliance Change"
  ],
  "detail": {
    "messageType": [
      "ComplianceChangeNotification"
    ]
  }
}
PATTERN

}

resource "aws_cloudwatch_event_target" "lambda_to_send_email" {
  rule      = aws_cloudwatch_event_rule.config_rules_non_compliant.name
  target_id = "config_non_compliant_email_${var.customer}-${var.env}"
  arn       = aws_lambda_function.config_rules_non_compliant_lambda.arn
}

resource "aws_lambda_function" "config_rules_non_compliant_lambda" {
  filename         = "lambdas/config_rules_non_compliant.zip"
  function_name    = "config_rules_non_compliant_lambda_${var.customer}-${var.env}"
  role             = "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/config_rules_non_compliant_role"
  handler          = "config_rules_non_compliant.lambda_handler"
  source_code_hash = filebase64sha256("lambdas/config_rules_non_compliant.zip")
  runtime          = "python3.8"
}

resource "aws_lambda_permission" "config_rules_non_compliant_lambda_perm" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.config_rules_non_compliant_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.config_rules_non_compliant.arn
}

