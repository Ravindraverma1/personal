#variable enable_occ_file_share should be set to "true" for this tf file to be executed
#1 [Customer Account] - add customer side lambda- verify timeout, concurrency from poc lambda
resource "aws_lambda_function" "occ-file-transfer" {
  count = var.enable_occ_file_share == "true" ? 1 : 0

  #function attributes
  function_name                  = "occ-file-transfer-${var.customer}-${var.env}"
  handler                        = "occ_file_transfer.lambda_handler"
  role                           = aws_iam_role.occ-file-transfer-lambda-role[0].arn
  runtime                        = "python3.8"
  timeout                        = 360
  filename                       = "lambdas/occ_file_transfer.zip"
  source_code_hash               = filebase64sha256("lambdas/occ_file_transfer.zip")
  reserved_concurrent_executions = 1

  environment {
    variables = {
      CUSTOMER             = var.customer
      ENV                  = var.env
      REGION               = var.aws_region
      SST_ACCOUNT_ID       = var.sst_account_id
      OCC_BUCKET_NAME      = "${var.occ_env_tag}-${var.aws_region}"
      CUSTOMER_DATA_BUCKET = aws_s3_bucket.cv-default-data-bucket.id
      SST_ASSUME_ROLE_NAME = var.occ_sst_role_name
    }
  }
}

#2a [SST account]- permission to be added to SST SNS for subscription to be enabled - via cli
#2b [SST Account] -update SNS permission to connect to this customer lambda
#####add 2a policy via cli#################, preferably in plan stage??

#updates lambda policy to allow SST SNS to invoke customer lambda
resource "aws_lambda_permission" "occ-sst-lambda-permission" {
  count         = var.enable_occ_file_share == "true" ? 1 : 0
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.occ-file-transfer[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = data.aws_sns_topic.occ-sns-topic[0].arn
}

#arn:aws:sns:eu-west-1:987485473618:occ-master-topic-euws1
#resource aws_lambda_function_event_invoke_config occ-lambda-to-sst-sns-map{
#  function_name = "${aws_lambda_function.occ-file-transfer.function_name}"
#}

data "aws_sns_topic" "occ-sns-topic" {
  count    = var.enable_occ_file_share == "true" ? 1 : 0
  provider = aws.occ-sst
  name     = var.occ_sns_topic_name
}

resource "aws_sns_topic_subscription" "occ-sns-topic-subscription" {
  count                  = var.enable_occ_file_share == "true" ? 1 : 0
  provider               = aws.occ-sns-cust
  topic_arn              = data.aws_sns_topic.occ-sns-topic[0].arn
  protocol               = "lambda"
  endpoint               = aws_lambda_function.occ-file-transfer[0].arn
  endpoint_auto_confirms = "true"
}

#data aws_sns_topic_policy "occ-sns-topic-policy-sst"{
#  count    = "${var.enable_occ_file_share == "true" ? 1 : 0}"
#  provider = "aws.occ-sst"
#  policy_id= "__default_policy_ID"
#}

#3 [Customer Account]
#a- add lambda permissions to reach SNS endpoint
#b - permission to put into customer data bucket - with key = occdata/
#1create role to be assumed by lambda
resource "aws_iam_role" "occ-file-transfer-lambda-role" {
  count = var.enable_occ_file_share == "true" ? 1 : 0

  name               = "occ-file-transfer-${var.customer}-${var.env}"
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

#2create basic execution role for Lambda
resource "aws_iam_role_policy_attachment" "occ-file-transfer-lambda-basic-exec-role" {
  count      = var.enable_occ_file_share == "true" ? 1 : 0
  role       = aws_iam_role.occ-file-transfer-lambda-role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#3create s3 access policy for lambda
data "aws_iam_policy_document" "occ-file-transfer-lambda-s3-access-policy-doc" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:PutObjectTagging",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data/occdata/*",
    ]
  }
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data",
    ]
  }
}

resource "aws_iam_policy" "occ-file-transfer-lambda-s3-access-policy" {
  count  = var.enable_occ_file_share == "true" ? 1 : 0
  name   = "occ-file-transfer-lambda-s3-access-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.occ-file-transfer-lambda-s3-access-policy-doc.json
}

#attach this policy to the occ-lambda role
resource "aws_iam_role_policy_attachment" "occ-file-transfer-lambda-s3-role" {
  count      = var.enable_occ_file_share == "true" ? 1 : 0
  role       = aws_iam_role.occ-file-transfer-lambda-role[0].name
  policy_arn = aws_iam_policy.occ-file-transfer-lambda-s3-access-policy[0].arn
}

#4-??anything remaining??- yes
#role for lambda to assume role
resource "aws_iam_policy" "occ_lambda_sst_access_role" {
  count       = var.enable_occ_file_share == "true" ? 1 : 0
  name        = "occ-lambda-sst-access-${var.customer}-${var.env}"
  path        = "/"
  description = "Allow customer lambda to assume this role"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "*"
        }
    ]
}
EOF

}

#attach this policy to the occ-lambda role
resource "aws_iam_role_policy_attachment" "occ-file-transfer-lambda-attachment" {
  count      = var.enable_occ_file_share == "true" ? 1 : 0
  role       = aws_iam_role.occ-file-transfer-lambda-role[0].name
  policy_arn = aws_iam_policy.occ_lambda_sst_access_role[0].arn
}

