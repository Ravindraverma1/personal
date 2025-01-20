####### Role For Config Service
resource "aws_iam_role" "config-role" {
  name               = "config-role"
  path               = "/service-role/"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY

}

data "aws_iam_policy_document" "config-policy-document" {
  statement {
    actions   = ["s3:PutObject"]
    effect    = "Allow"
    resources = ["arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-config-bucket/AWSLogs/${data.aws_caller_identity.env_account.account_id}/*"]
    condition {
      test     = "StringLike"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    actions   = ["s3:GetBucketAcl"]
    effect    = "Allow"
    resources = ["arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-config-bucket"]
  }
}

resource "aws_iam_policy" "config-policy" {
  name   = "config-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.config-policy-document.json
}

resource "aws_iam_role_policy_attachment" "config_policy_att_1" {
  role       = aws_iam_role.config-role.name
  policy_arn = aws_iam_policy.config-policy.arn
}

resource "aws_iam_role_policy_attachment" "config_policy_att_2" {
  role       = aws_iam_role.config-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

####### S3 Bucket For Config Service 

resource "aws_s3_bucket" "config_bucket" {
  bucket        = "axiom-${data.aws_caller_identity.env_account.account_id}-config-bucket"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = {
    Name = "axiom-${data.aws_caller_identity.env_account.account_id}-config-bucket"
  }

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Deny GetObject without secureTransport",
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Deny",
      "Resource": "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-config-bucket/*",
      "Principal": "*",
      "Condition": {
        "Bool": {
         "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_public_access_block" "public_block_config" {
  bucket                  = aws_s3_bucket.config_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object" "AWSLogs" {
  bucket = aws_s3_bucket.config_bucket.id
  acl    = "private"
  key    = "AWSLogs/${data.aws_caller_identity.env_account.account_id}/Config/${var.aws_region}"
  source = "/dev/null"
}

####### Config Service Definition
# Use bash script in place of static definition of all regions 
resource "null_resource" "config_service_definition_into_all_regions" {
  count = var.enable_aws_config == "true" ? 1 : 0
  provisioner "local-exec" {
    command = "sh ../scripts/config-srv-all-region.sh create ${var.env_aws_profile} ${aws_s3_bucket.config_bucket.bucket} ${aws_iam_role.config-role.arn} ${var.aws_region}"
  }
}

####### Config Rules Definition compliance with CIS Benchmark 

resource "aws_s3_bucket_object" "config-rules-yaml" {
  count  = var.enable_aws_config == "true" ? 1 : 0
  bucket = aws_s3_bucket.config_bucket.id
  acl    = "private"
  key    = "AWSLogs/${data.aws_caller_identity.env_account.account_id}/Config/${var.aws_region}/axiom-cis.yaml"
  source = "../cis/axiom-cis.yaml"
  etag   = md5("../cis/axiom-cis.yaml")
}

resource "aws_cloudformation_stack" "config_rules" {
  count        = var.enable_aws_config == "true" ? 1 : 0
  name         = "ConfigRules-CIS-L1"
  capabilities = ["CAPABILITY_IAM"]
  on_failure   = "DELETE"
  parameters = {
    ProfileLevel                                = "Level 2"
    NotificationEmailAddressForCloudWatchAlarms = var.cis_notification_email
    ConfigBucket                                = aws_s3_bucket.config_bucket.bucket
    SecuritySNSTopic                            = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Security-Notification-${data.aws_caller_identity.env_account.account_id}"
  }
  template_url = "https://s3.amazonaws.com/${aws_s3_bucket.config_bucket.bucket}/AWSLogs/${data.aws_caller_identity.env_account.account_id}/Config/${var.aws_region}/axiom-cis.yaml"
  depends_on = [
    aws_s3_bucket_object.config-rules-yaml,
    null_resource.config_service_definition_into_all_regions,
  ]
}

