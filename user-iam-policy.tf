data "aws_iam_policy_document" "cv-default-ses-policy-doc" {
  statement {
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]

    resources = [
      "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:*",
    ]

    condition {
      test     = "ForAllValues:StringLike"
      variable = "ses:Recipients"
      values   = var.infra_domains
    }
  }
}

resource "aws_iam_policy" "cv-default-ses-policy" {
  name   = "cv-default-ses-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.cv-default-ses-policy-doc.json
}

resource "aws_iam_group_policy_attachment" "cv-default-ses-bucket-policy" {
  group      = aws_iam_group.emailsenders.name
  policy_arn = aws_iam_policy.cv-default-ses-policy.arn
}

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = "90"
  password_reuse_prevention      = "24"
}

# outbound transfer
data "aws_iam_policy_document" "outbound-transfer-external-policy" {
  count = var.enable_outbound_transfer == "true" &&  var.enable_byok == "false" ? 1 : 0
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [
      aws_kms_key.outbound-transfer[0].arn,
    ]

    condition {
      test     = "ForAnyValue:IpAddress"
      variable = "aws:SourceIp"
      values   = var.source_cidr_blocks_allowed
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.cv-default-key-bucket.arn}/${var.customer}-${var.env}-outbound-key.pub",
    ]

    condition {
      test     = "ForAnyValue:IpAddress"
      variable = "aws:SourceIp"
      values   = var.source_cidr_blocks_allowed
    }
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.outbound-data-bucket[0].arn,
    ]

    condition {
      test     = "ForAnyValue:IpAddress"
      variable = "aws:SourceIp"
      values   = var.source_cidr_blocks_allowed
    }
  }

  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.outbound-data-bucket[0].arn}/*",
    ]

    condition {
      test     = "ForAnyValue:IpAddress"
      variable = "aws:SourceIp"
      values   = var.source_cidr_blocks_allowed
    }
  }
# VPCE start:
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [
      aws_kms_key.outbound-transfer[0].arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values = var.source_vpces_allowed
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.cv-default-key-bucket.arn}/${var.customer}-${var.env}-outbound-key.pub",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values = var.source_vpces_allowed
    }
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.outbound-data-bucket[0].arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values = var.source_vpces_allowed
    }
  }

  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.outbound-data-bucket[0].arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values = var.source_vpces_allowed
    }
  }
}

resource "aws_iam_policy" "outbound-transfer-external-policy" {
  count  = var.enable_outbound_transfer == "true" && var.enable_byok == "false" ? 1 : 0
  name   = "outbound-transfer-external-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.outbound-transfer-external-policy[0].json
}

resource "aws_iam_group_policy_attachment" "outbound-transfer-external-policy-att" {
  count      = var.enable_outbound_transfer == "true" && var.enable_byok == "false" ? 1 : 0
  group      = aws_iam_group.outboundtransfer[0].name
  policy_arn = aws_iam_policy.outbound-transfer-external-policy[0].arn
}

# outbound transfer external policy WORM
data "aws_iam_policy_document" "outbound-transfer-worm-external-policy" {
  count = var.enable_worm_compliance == "true" && var.enable_byok == "false" ? 1 : 0
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [
      aws_kms_key.outbound-transfer[0].arn
    ]

    condition {
      test     = "ForAnyValue:IpAddress"
      variable = "aws:SourceIp"
      values   = var.source_cidr_blocks_allowed
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.cv-default-key-bucket.arn}/${var.customer}-${var.env}-outbound-key.pub",
    ]

    condition {
      test     = "ForAnyValue:IpAddress"
      variable = "aws:SourceIp"
      values   = var.source_cidr_blocks_allowed
    }
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.cv-worm-data-bucket[0].arn,
    ]

    condition {
      test     = "ForAnyValue:IpAddress"
      variable = "aws:SourceIp"
      values   = var.source_cidr_blocks_allowed
    }
  }

  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.cv-worm-data-bucket[0].arn}/*",
    ]

    condition {
      test     = "ForAnyValue:IpAddress"
      variable = "aws:SourceIp"
      values   = var.source_cidr_blocks_allowed
    }
  }

# VPCE start:
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [
      aws_kms_key.outbound-transfer[0].arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values = var.source_vpces_allowed
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.cv-default-key-bucket.arn}/${var.customer}-${var.env}-outbound-key.pub",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values = var.source_vpces_allowed
    }
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.cv-worm-data-bucket[0].arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values = var.source_vpces_allowed
    }
  }

  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.cv-worm-data-bucket[0].arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values = var.source_vpces_allowed
    }
  }
}

resource "aws_iam_policy" "outbound-transfer-worm-external-policy" {
  count  = var.enable_worm_compliance == "true" &&  var.enable_byok == "false" ? 1 : 0
  name   = "outbound-transfer-worm-external-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.outbound-transfer-worm-external-policy[0].json
}

resource "aws_iam_group_policy_attachment" "outbound-transfer-worm-external-policy-att" {
  count      = var.enable_worm_compliance == "true" &&  var.enable_byok == "false" ? 1 : 0
  group      = aws_iam_group.outboundtransfer[0].name
  policy_arn = aws_iam_policy.outbound-transfer-worm-external-policy[0].arn
}

# KMS key policy applicable for use across all CloudWatch log groups
data "aws_iam_policy_document" "cloudwatch_log_kms_policy_doc" {
  statement {
    effect  = "Allow"
    actions = ["kms:*"]
    resources = ["*"]
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root"]
      type = "AWS"
    }
  }
  statement {
    effect  = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]
    principals {
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
      type = "Service"
    }
    condition {
      test = "ArnLike"
      values = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:*"]
      variable = "kms:EncryptionContext:aws:logs:arn"
    }
  }
}
