provider "aws" {
  region                  = var.aws_region
  shared_credentials_file = pathexpand("~/.aws/credentials")
  profile                 = var.env_aws_profile
  version                 = "~> 3.74.1"
}

#Fortanix IAM user resources for BYOK
resource "aws_iam_user" "fortanix" {
  count = var.enable_byok == "true" ? 1 : 0
  name  = "${var.customer}-${var.env}-fortanix-user"
  path  = "/"
}

resource "aws_iam_access_key" "fortanix" {
  count = var.enable_byok == "true" ? 1 : 0
  user  = aws_iam_user.fortanix[0].name
}

data "aws_iam_policy_document" "fortanix-user-policy-doc" {
  count  = var.enable_byok == "true" ? 1 : 0
  statement {
    actions = [
      "kms:EnableKey",
      "kms:GetPublicKey",
      "kms:ImportKeyMaterial",
      "kms:UntagResource",
      "kms:PutKeyPolicy",
      "kms:ListResourceTags",
      "kms:CancelKeyDeletion",
      "kms:GetParametersForImport",
      "kms:TagResource",
      "kms:GetKeyRotationStatus",
      "kms:ScheduleKeyDeletion",
      "kms:DescribeKey",
      "kms:CreateKey",
      "kms:CreateGrant",
      "kms:EnableKeyRotation",
      "kms:ListKeyPolicies",
      "kms:ListRetirableGrants",
      "kms:GetKeyPolicy",
      "kms:DeleteImportedKeyMaterial",
      "kms:DisableKey",
      "kms:DisableKeyRotation",
      "kms:RetireGrant",
      "kms:ListGrants",
      "kms:UpdateAlias",
      "kms:ListKeys",
      "kms:RevokeGrant",
      "kms:ListAliases",
      "kms:CreateAlias",
      "kms:DeleteAlias",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "fortanix-user-policy" {
  count  = var.enable_byok == "true" ? 1 : 0
  name   = "fortanix-user-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.fortanix-user-policy-doc[0].json
}


resource "aws_iam_user_policy_attachment" "fortanix-user-policy" {
  count      = var.enable_byok == "true" ? 1 : 0
  user       = aws_iam_user.fortanix[0].name
  policy_arn = aws_iam_policy.fortanix-user-policy[0].arn
}

#Fortanix IAM user ssm parameters
data "aws_kms_alias" "ssm_aws_key" {
  count  = var.enable_byok == "true" ? 1 : 0
  name   = "alias/aws/ssm"
}

resource "aws_ssm_parameter" "fortanix_access_key_id" {
  count  = var.enable_byok == "true" ? 1 : 0
  name   = "/${var.customer}/${var.env}/fortanix_access_key_id"
  type   = "SecureString"
  value  = aws_iam_access_key.fortanix[0].id
  key_id = data.aws_kms_alias.ssm_aws_key[0].target_key_id
}

resource "aws_ssm_parameter" "fortanix_secret_access_key" {
  count  = var.enable_byok == "true" ? 1 : 0
  name   = "/${var.customer}/${var.env}/fortanix_secret_access_key"
  type   = "SecureString"
  value  = aws_iam_access_key.fortanix[0].secret
  key_id = data.aws_kms_alias.ssm_aws_key[0].target_key_id
}

data "aws_ssm_parameter" "fortanix_access_key_id" {
  count      = var.enable_byok == "true" ? 1 : 0
  depends_on = [aws_ssm_parameter.fortanix_access_key_id]
  name       = "/${var.customer}/${var.env}/fortanix_access_key_id"
}

data "aws_ssm_parameter" "fortanix_secret_access_key" {
  count      = var.enable_byok == "true" ? 1 : 0
  depends_on = [aws_ssm_parameter.fortanix_secret_access_key]
  name       = "/${var.customer}/${var.env}/fortanix_secret_access_key"
}
