resource "aws_lambda_function" "legalhold_on_object" {
  count            = var.enable_worm_compliance == "true" ? 1 : 0
  filename         = "lambdas/put_legalhold_on_s3object.zip"
  function_name    = "legalhold_on_object_${var.customer}-${var.env}"
  role             = aws_iam_role.legalhold_on_object_lambda[0].arn
  handler          = "put_legalhold_on_s3object.lambda_handler"
  source_code_hash = filebase64sha256("lambdas/put_legalhold_on_s3object.zip")
  runtime          = "python3.8"
  timeout          = "120"
}

resource "aws_lambda_permission" "worm-data-bucket-s3-perm" {
  count         = var.enable_worm_compliance == "true" ? 1 : 0
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.legalhold_on_object[0].function_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.trigger-worm-s3-ref[0].arn
}

resource "aws_s3_bucket_notification" "worm-data-bucket-s3-notify" {
  count  = var.enable_worm_compliance == "true" ? 1 : 0
  bucket = data.aws_s3_bucket.trigger-worm-s3-ref[0].id
  lambda_function {
    lambda_function_arn = aws_lambda_function.legalhold_on_object[0].arn
    events              = ["s3:ObjectCreated:Put"]
  }
  depends_on = [
    aws_lambda_permission.worm-data-bucket-s3-perm
  ]
}

resource "aws_iam_role_policy" "worm_compliance_policy" {
  count = var.enable_worm_compliance == "true" ? 1 : 0
  name  = "worm_compliance_policy"
  role  = aws_iam_role.legalhold_on_object_lambda[0].id

  policy = <<EOF
{
"Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:*"
        },
        {
            "Effect": "Allow",
            "Action": ["s3:PutObjectLegalHold"],
            "Resource": "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data/*"
        }
    ]
}
EOF

}

resource "aws_iam_role" "legalhold_on_object_lambda" {
  count              = var.enable_worm_compliance == "true" ? 1 : 0
  name               = "legalhold-lambda-role-${var.customer}-${var.env}"
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

