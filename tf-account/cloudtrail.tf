data "aws_iam_account_alias" "current" {
}

data "aws_caller_identity" "env_account" {
}

##
#  Define role for cloudtrail 
##
resource "aws_iam_role" "cloudtrail" {
  name               = "${var.cloudtrail_trail_name}-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudTrailAllow",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

##
# Define Policy to allow create LogStream and Put events
##

resource "aws_iam_role_policy" "cloudtrail" {
  name   = "cloudtrail-to-cloudwatch-policy"
  role   = aws_iam_role.cloudtrail.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailCreateLogStream",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:log-group:cis-global-cloudtrail-log-group*"
      ]
    }
  ]
}
EOF

}

##
# Definition of CloudTrail service to Audit Account S3 bucket and KMS encryption (of Audit Account too)
#CT's s3 bucket and KMS key need to be in the same region
resource "aws_cloudtrail" "ax_cloudtrail" {
  name                          = var.cloudtrail_trail_name
  is_multi_region_trail         = var.cloudtrail_is_multi_region_trail
  s3_bucket_name                = "${var.cloudtrail_s3_bucket}-${var.aws_region}"
  s3_key_prefix                 = data.aws_iam_account_alias.current.account_alias
  enable_logging                = var.cloudtrail_enable_logging
  enable_log_file_validation    = var.cloudtrail_enable_log_file_validation
  include_global_service_events = var.cloudtrail_include_global_service_events
  kms_key_id                    = var.cloudtrail_kms_arn_audit_account
  cloud_watch_logs_group_arn    = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:log-group:cis-global-cloudtrail-log-group:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail.arn
  depends_on = [
    aws_iam_role_policy.cloudtrail,
    aws_cloudwatch_log_group.cloudtrail_log_group,
    aws_iam_role.cloudtrail,
  ]

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type = "AWS::S3::Object"

      values = [
        "arn:aws:s3:::",
      ]
    }
  }

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type = "AWS::Lambda::Function"

      values = [
        "arn:aws:lambda",
      ]
    }
  }
}

