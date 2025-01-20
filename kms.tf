resource "aws_kms_key" "a" {
  count               = var.enable_byok == "false" ? 1 : 0
  description         = "Packer 1"
  enable_key_rotation = true
  policy              = <<EOF
{
    "Version": "2012-10-17",
    "Id": "key-default-1",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root",
                    "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/cv-${var.customer}-${var.env}"
                ]
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
EOF

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-kms_packer"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_kms_alias" "a" {
  count         = var.enable_byok == "false" ? 1 : 0
  name          = "alias/key-alias-${var.customer}-${var.env}"
  target_key_id = aws_kms_key.a[0].key_id
}

resource "aws_kms_key" "backup" {
  description         = "Backup Customer Master Key for ${var.customer}-${var.env}"
  enable_key_rotation = true

  tags = {
    Name        = "backup-${var.customer}-${var.env}-${var.aws_region}"
    region      = var.business_region[var.aws_region]
    customer    = var.customer
    Environment = var.env
  }
}

resource "aws_kms_alias" "backup-alias" {
  name          = "alias/backup-${var.customer}-${var.env}"
  target_key_id = aws_kms_key.backup.key_id
}

resource "aws_kms_key" "outbound-transfer" {
  count               = var.enable_outbound_transfer == "true" && var.enable_byok == "false" ? 1 : 0
  description         = "Outbound Data Transfer Customer Master Key for ${var.customer}-${var.env}"
  enable_key_rotation = true
  policy              = var.jenkins_env != "development" ? data.aws_iam_policy_document.outbound_transfer_policy_doc[0].json : data.aws_iam_policy_document.outbound_transfer_policy_dev_doc[0].json
  tags = {
    Name        = "outbound-transfer-${var.customer}-${var.env}-${var.aws_region}"
    region      = var.business_region[var.aws_region]
    customer    = var.customer
    Environment = var.env
  }
}

data "aws_iam_policy_document" "outbound_transfer_policy_doc" {
  count = var.jenkins_env != "development" && var.enable_outbound_transfer == "true" && var.enable_byok == "false" ? 1 : 0
  statement {
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalType"
      values   = ["Account"]
    }
  }

  statement {
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-sst-jenkins",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-admin"
      ]
    }
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:user/${var.customer}-${var.env}-outbound-transfer-user"]
    }
  }
}

data "aws_iam_policy_document" "outbound_transfer_policy_dev_doc" {
  count = var.jenkins_env == "development" && var.enable_outbound_transfer == "true" && var.enable_byok == "false" ? 1 : 0
  statement {
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalType"
      values   = ["Account"]
    }
  }

  statement {
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-sst-jenkins",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-dev",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-dev-admin"
      ]
    }
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:user/${var.customer}-${var.env}-outbound-transfer-user"]
    }
  }
}

resource "aws_kms_alias" "outbound-transfer" {
  count         = var.enable_outbound_transfer == "true" && var.enable_byok == "false" ? 1 : 0
  name          = "alias/outbound-transfer-${var.customer}-${var.env}"
  target_key_id = aws_kms_key.outbound-transfer[0].key_id
}

resource "aws_kms_key" "cloudwatch_kms_key" {
  description         = "CloudWatch logs KMS key"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.cloudwatch_log_kms_policy_doc.json

  tags = {
    Name        = "cloudwatch-${var.customer}-${var.env}-${var.aws_region}"
    region      = var.business_region[var.aws_region]
    customer    = var.customer
    Environment = var.env
  }
}

resource "aws_kms_alias" "cloudwatch_kms_alias" {
  name          = "alias/cloudwatch-key-${var.customer}-${var.env}"
  target_key_id = aws_kms_key.cloudwatch_kms_key.key_id
}

resource "aws_kms_key" "archive_ff" {
  count               = var.enable_byok == "false" ? 1 : 0
  description         = "kms key for archive db source file folder bucket"
  enable_key_rotation = true
  policy              = var.jenkins_env != "development" ? data.aws_iam_policy_document.archive_ff_policy_doc[0].json : data.aws_iam_policy_document.archive_ff_policy_dev_doc[0].json
  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-kms_archive_ff"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

data "aws_iam_policy_document" "archive_ff_policy_doc" {
  count = var.enable_byok == "false" && var.jenkins_env != "development" ? 1 : 0
  statement {
    actions = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root"
      ]
    }
  }

  statement {
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-admin",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/cv-${var.customer}-${var.env}",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/tomcat-${var.customer}-${var.env}"
      ]
    }
  }
}

data "aws_iam_policy_document" "archive_ff_policy_dev_doc" {
  count = var.enable_byok == "false" && var.jenkins_env == "development" ? 1 : 0
  statement {
    actions = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root"
      ]
    }
  }

  statement {
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-sst-jenkins",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-dev",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-dev-admin",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/cv-${var.customer}-${var.env}",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/tomcat-${var.customer}-${var.env}"
      ]
    }
  }
}

resource "aws_kms_alias" "archive_ff" {
  count         = var.enable_byok == "false" ? 1 : 0
  name          = "alias/key-alias-archive-ff-${var.customer}-${var.env}"
  target_key_id = aws_kms_key.archive_ff[0].key_id
}

resource "aws_kms_key" "worm_bucket" {
  count               = var.enable_worm_compliance == "true" && var.enable_byok == "false" ? 1 : 0
  description         = "kms key for archive db source file folder bucket"
  enable_key_rotation = true
  policy              = var.jenkins_env != "development" ? data.aws_iam_policy_document.worm_bucket_policy_doc[0].json : data.aws_iam_policy_document.worm_bucket_policy_dev_doc[0].json
  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-kms_worm_bucket"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

data "aws_iam_policy_document" "worm_bucket_policy_doc" {
  count = var.enable_worm_compliance == "true" && var.enable_byok == "false" && var.jenkins_env != "development" ? 1 : 0
  statement {
    actions = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root"
      ]
    }
  }

  statement {
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-admin",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/cv-${var.customer}-${var.env}"
      ]
    }
  }
}

data "aws_iam_policy_document" "worm_bucket_policy_dev_doc" {
  count = var.enable_worm_compliance == "true" && var.enable_byok == "false" && var.jenkins_env == "development" ? 1 : 0
  statement {
    actions = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root"
      ]
    }
  }

  statement {
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-sst-jenkins",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-dev",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-dev-admin",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/cv-${var.customer}-${var.env}"
      ]
    }
  }
}

resource "aws_kms_alias" "worm_bucket" {
  count         = var.enable_worm_compliance == "true" && var.enable_byok == "false" ? 1 : 0
  name          = "alias/key-alias-worm-bucket-${var.customer}-${var.env}"
  target_key_id = aws_kms_key.worm_bucket[count.index].key_id
}

resource "aws_kms_alias" "pgp_ff" {
  count         = var.enable_pgp == "true" && var.enable_byok == "false" ? 1 : 0
  name          = "alias/key-alias-pgp-ff-${var.customer}-${var.env}"
  target_key_id = aws_kms_key.pgp_ff[0].key_id
}

resource "aws_kms_key" "pgp_ff" {
  count               = var.enable_pgp == "true" && var.enable_byok == "false" ? 1 : 0
  description         = "kms key for pgp file folder bucket"
  enable_key_rotation = true
  policy              = var.jenkins_env != "development" ? data.aws_iam_policy_document.pgp_ff_policy_doc[0].json : data.aws_iam_policy_document.pgp_ff_policy_dev_doc[0].json
  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-kms_pgp_ff"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

data "aws_iam_policy_document" "pgp_ff_policy_dev_doc" {
  count = var.enable_pgp == "true" && var.enable_byok == "false" && var.jenkins_env == "development" ? 1 : 0
  statement {
    actions = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root"
      ]
    }
  }

  statement {
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-sst-jenkins",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-dev",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-dev-admin",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/cv-${var.customer}-${var.env}"
      ]
    }
  }
}

data "aws_iam_policy_document" "pgp_ff_policy_doc" {
  count = var.enable_pgp == "true" && var.enable_byok == "false" && var.jenkins_env != "development" ? 1 : 0
  statement {
    actions = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root"
      ]
    }
  }

  statement {
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-admin",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/cv-${var.customer}-${var.env}"
      ]
    }
  }
}

data "aws_iam_policy_document" "reporting_files_ff_policy_dev_doc" {
  count = var.enable_byok == "false" && var.jenkins_env == "development" ? 1 : 0
  statement {
    actions = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root"
      ]
    }
  }

  statement {
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-sst-jenkins",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-dev",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-dev-admin",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/cv-${var.customer}-${var.env}"
      ]
    }
  }
}

data "aws_iam_policy_document" "reporting_files_ff_policy_doc" {
  count = var.enable_byok == "false" && var.jenkins_env != "development" ? 1 : 0
  statement {
    actions = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root"
      ]
    }
  }

  statement {
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-admin",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/cv-${var.customer}-${var.env}"
      ]
    }
  }
}

resource "aws_kms_key" "reporting_files_ff" {
  count               = var.enable_byok == "false" ? 1 : 0
  description         = "kms key for reporting files file folder bucket"
  enable_key_rotation = true
  policy              = var.jenkins_env != "development" ? data.aws_iam_policy_document.reporting_files_ff_policy_doc[0].json : data.aws_iam_policy_document.reporting_files_ff_policy_dev_doc[0].json
  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-kms_reporting_files_ff"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_kms_alias" "reporting_files_ff" {
  count         = var.enable_byok == "false" ? 1 : 0
  name          = "alias/key-alias-reporting-files-ff-${var.customer}-${var.env}"
  target_key_id = aws_kms_key.reporting_files_ff[0].key_id
}


resource "aws_kms_key" "emr_data" {
  count               = var.enable_spark == "true" ? 1 : 0
  description         = "KMS Key for EMR data S3 bucket and EMR security conf"
  enable_key_rotation = true
  policy              = <<EOF
{
    "Version": "2012-10-17",
    "Id": "key-default-1",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root"
                ]
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
EOF

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-emr-data"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_kms_alias" "emr_data" {
  count         = var.enable_spark == "true" ? 1 : 0
  name          = "alias/emr-data-${var.customer}-${var.env}"
  target_key_id = aws_kms_key.emr_data[0].key_id
}

data "aws_iam_policy_document" "emr_staging_policy_dev_doc" {
  count = var.enable_spark == "true" && var.jenkins_env == "development" || var.keep_spark_data == "true" && var.jenkins_env == "development" ? 1 : 0
  statement {
    actions = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root"
      ]
    }
  }

  statement {
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-sst-jenkins",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-dev",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-dev-admin",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/cv-${var.customer}-${var.env}"
      ]
    }
  }
}

data "aws_iam_policy_document" "emr_staging_policy_doc" {
  count = var.enable_spark == "true" && var.jenkins_env != "development" || var.keep_spark_data == "true" && var.jenkins_env != "development" ? 1 : 0
  statement {
    actions = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root"
      ]
    }
  }

  statement {
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/axiomsl-iam-admin",
        "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/cv-${var.customer}-${var.env}"
      ]
    }
  }
}

resource "aws_kms_key" "emr_staging" {
  count               = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  description         = "KMS Key for EMR staging S3 bucket and EMR security conf"
  enable_key_rotation = true
  policy              = var.jenkins_env != "development" ? data.aws_iam_policy_document.emr_staging_policy_doc[0].json : data.aws_iam_policy_document.emr_staging_policy_dev_doc[0].json
  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-emr-staging"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_kms_alias" "emr_staging" {
  count         = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  name          = "alias/emr-staging-${var.customer}-${var.env}"
  target_key_id = aws_kms_key.emr_staging[0].key_id
}

resource "aws_kms_grant" "emr_staging_key_grant_exe" {
  count  = var.enable_spark == "true" ? 1 : 0
  name   = "emr_staging_grant-exe-${var.customer}-${var.env}"
  key_id = aws_kms_key.emr_staging[0].key_id
  #grantee_principal = module.exe_emr_cluster.ec2_role
  grantee_principal = "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/${var.namespace}-${var.stage}-${var.name}-exe-${var.customer}-${var.env}-ec2"
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey", "ReEncryptFrom", "ReEncryptTo", "DescribeKey"]
  depends_on        = [module.exe_emr_cluster.ec2_role]
}

resource "aws_kms_grant" "emr_data_key_grant_exe" {
  count  = var.enable_spark == "true" ? 1 : 0
  name   = "emr_data_grant-exe-${var.customer}-${var.env}"
  key_id = aws_kms_key.emr_data[0].key_id
  #grantee_principal = module.exe_emr_cluster.ec2_role
  grantee_principal = "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/${var.namespace}-${var.stage}-${var.name}-exe-${var.customer}-${var.env}-ec2"
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey", "ReEncryptFrom", "ReEncryptTo", "DescribeKey"]
  depends_on        = [module.exe_emr_cluster.ec2_role]
}

resource "aws_kms_grant" "emr_data_key_grant_thrift" {
  count  = var.enable_spark == "true" ? 1 : 0
  name   = "emr_data_grant-thrift-${var.customer}-${var.env}"
  key_id = aws_kms_key.emr_data[0].key_id
  #grantee_principal = module.thrift_emr_cluster.ec2_role
  grantee_principal = "arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:role/${var.namespace}-${var.stage}-${var.name}-thrift-${var.customer}-${var.env}-ec2"
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey", "ReEncryptFrom", "ReEncryptTo", "DescribeKey"]
  depends_on        = [module.thrift_emr_cluster.ec2_role]
}