data "aws_ssm_parameter" "fortanix_access_key_id" {
  count      = var.enable_byok == "true" ? 1 : 0
  name       = "/${var.customer}/${var.env}/fortanix_access_key_id"
}

data "aws_ssm_parameter" "fortanix_secret_access_key" {
  count      = var.enable_byok == "true" ? 1 : 0
  name       = "/${var.customer}/${var.env}/fortanix_secret_access_key"
}


#rds encryption key
data "aws_kms_alias" "rds_fortanix_key" {
  count  = var.enable_byok == "true" ? 1 : 0
  name   = "alias/rds-${var.customer}-${var.env}-fortanix"
}

#pgp ff encryption key
data "aws_kms_alias" "pgp_fortanix_key" {
  count  = var.enable_byok == "true" && var.enable_pgp == "true" ? 1 : 0
  name   = "alias/key-alias-pgp-ff-${var.customer}-${var.env}-fortanix"
}

#defaults3 ff encryption key
data "aws_kms_alias" "default_s3_ff_fortanix_key" {
  count  = var.enable_byok == "true" ? 1 : 0
  name   = "alias/key-alias-s3-ff-${var.customer}-${var.env}-fortanix"
}

#Archive ff encryption key
data "aws_kms_alias" "archive_ff_fortanix_key" {
  count  = var.enable_byok == "true" ? 1 : 0
  name   = "alias/key-alias-archive-ff-${var.customer}-${var.env}-fortanix"
}

#Reporting ff encryption key
data "aws_kms_alias" "reporting_files_ff_fortanix_key" {
  count  = var.enable_byok == "true" ? 1 : 0
  name   = "alias/key-alias-reporting-files-ff-${var.customer}-${var.env}-fortanix"
}

#worm-bucket encryption key
data "aws_kms_alias" "worm_bucket_fortanix_key" {
  count  = var.enable_byok == "true" && var.enable_worm_compliance == "true" ? 1 : 0
  name   = "alias/key-alias-worm-bucket-${var.customer}-${var.env}-fortanix"
}

#outbound transfer encryption key
data "aws_kms_alias" "outbound-transfer_fortanix_key" {
  count  = var.enable_byok == "true" && var.enable_outbound_transfer == "true" ? 1 : 0
  name   = "alias/outbound-transfer-${var.customer}-${var.env}-fortanix"
}


data "aws_iam_policy_document" "outbound-transfer-worm-external-policy_fortanix" {
  count = var.enable_worm_compliance == "true" && var.enable_byok == "true" ? 1 : 0
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [
      data.aws_kms_alias.outbound-transfer_fortanix_key[0].target_key_arn,
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
      data.aws_kms_alias.outbound-transfer_fortanix_key[0].target_key_arn,
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

resource "aws_iam_policy" "outbound-transfer-worm-external-policy_fortanix" {
  count  = var.enable_worm_compliance == "true" &&  var.enable_byok == "true" ? 1 : 0
  name   = "outbound-transfer-worm-external-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.outbound-transfer-worm-external-policy_fortanix[0].json
}

resource "aws_iam_group_policy_attachment" "outbound-transfer-worm-external-policy-att_fortanix" {
  count      = var.enable_worm_compliance == "true" &&  var.enable_byok == "true" ? 1 : 0
  group      = aws_iam_group.outboundtransfer[0].name
  policy_arn = aws_iam_policy.outbound-transfer-worm-external-policy_fortanix[0].arn
}


# outbound transfer external policy
data "aws_iam_policy_document" "outbound-transfer-external-policy_fortanix" {
  count = var.enable_outbound_transfer == "true" &&  var.enable_byok == "true" ? 1 : 0
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [
      data.aws_kms_alias.outbound-transfer_fortanix_key[0].target_key_arn,
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
#VPCE start:
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [
      data.aws_kms_alias.outbound-transfer_fortanix_key[0].target_key_arn,
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

resource "aws_iam_policy" "outbound-transfer-external-policy_fortanix" {
  count  = var.enable_outbound_transfer == "true" && var.enable_byok == "true" ? 1 : 0
  name   = "outbound-transfer-external-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.outbound-transfer-external-policy_fortanix[0].json
}

resource "aws_iam_group_policy_attachment" "outbound-transfer-external-policy-att_fortanix" {
  count      = var.enable_outbound_transfer == "true" && var.enable_byok == "true" ? 1 : 0
  group      = aws_iam_group.outboundtransfer[0].name
  policy_arn = aws_iam_policy.outbound-transfer-external-policy_fortanix[0].arn
}