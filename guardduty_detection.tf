resource "aws_lambda_function" "guardduty_instance_incident" {
  filename         = "lambdas/guardduty_instance_incident.zip"
  function_name    = "guardduty_instance_incident_${var.customer}-${var.env}"
  role             = "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/guardduty-instance-incident-role"
  handler          = "guardduty_instance_incident.lambda_handler"
  source_code_hash = filebase64sha256("lambdas/guardduty_instance_incident.zip")
  runtime          = "python3.8"
  timeout          = "120"
}

resource "aws_lambda_permission" "allow_cloudwatch_instance_incident" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.guardduty_instance_incident.function_name
  principal     = "events.amazonaws.com"
}

resource "aws_cloudwatch_event_rule" "guardduty_instance_incident" {
  name        = "guardduty_instance_incident_${var.customer}-${var.env}"
  description = "Send guard duty events to the handling lambda and act"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.guardduty"
  ],
  "detail-type": [
    "GuardDuty Finding"
  ]
}
PATTERN

}

resource "aws_cloudwatch_event_target" "guardduty_instance_incident" {
  rule      = aws_cloudwatch_event_rule.guardduty_instance_incident.name
  target_id = "guardduty_instance_incident_lambda_${var.customer}-${var.env}"
  arn       = aws_lambda_function.guardduty_instance_incident.arn
}

##S3 policy change detection###

resource "aws_cloudwatch_event_rule" "s3_policy_incident" {
  name        = "s3_policy_incident_${var.customer}-${var.env}"
  description = "Send s3 policy events to the handling lambda and act"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.s3"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "s3.amazonaws.com"
     ],
     "eventName": [
      "PutBucketPolicy",
      "DeleteBucketPolicy",
      "DeleteBucketEncryption",
      "PutBucketEncryption"
    ]
 }
}
PATTERN

}

resource "aws_cloudwatch_event_target" "s3_policy_incident" {
  rule      = aws_cloudwatch_event_rule.s3_policy_incident.name
  target_id = "guardduty_instance_incident_lambda_${var.customer}-${var.env}"
  arn       = aws_lambda_function.guardduty_instance_incident.arn
}

