locals {
  # db-auditing accounts mapping
  # see https://docs.aws.amazon.com/redshift/latest/mgmt/db-auditing.html
  db_audit_accounts = {
    us-east-1      = "193672423079"
    us-east-2      = "391106570357"
    us-west-1      = "262260360010"
    us-west-2      = "902366379725"
    ap-east-1      = "313564881002"
    ap-south-1     = "865932855811"
    ap-northeast-3 = "090321488786"
    ap-northeast-2 = "760740231472"
    ap-southeast-1 = "361669875840"
    ap-southeast-2 = "762762565011"
    ap-northeast-1 = "404641285394"
    ca-central-1   = "907379612154"
    eu-central-1   = "053454850223"
    eu-west-1      = "210876761215"
    eu-west-2      = "307160386991"
    eu-west-3      = "915173422425"
    eu-north-1     = "729911121831"
    me-south-1     = "013126148197"
    sa-east-1      = "075028567923"
  }
}

# Save all relevant code required by Terraform so as to allow debugging and re-applying from anywhere
resource "aws_s3_bucket_object" "terraform-code" {
  bucket     = var.tfstate_bucket_name
  key        = "terraform-code.tar.gz"
  source     = "temp/terraform-code.tar.gz"
  depends_on = [null_resource.create-terraform-code-archive]
  etag       = timestamp()
}

resource "null_resource" "create-terraform-code-archive" {
  triggers = {
    x = timestamp()
  }

  provisioner "local-exec" {
    command = "tar -zcf temp/terraform-code.tar.gz *.tf terraform.tfvars cis config lambdas modules playbooks scripts templates"
  }

  depends_on = [null_resource.dns_update_zip]
}

resource "aws_s3_bucket" "client-bucket" {
  bucket = "${var.customer}-${var.env}-${var.aws_region}-installation-data"
  acl    = "private"

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
    Name        = "${var.customer}-${var.env}-${var.aws_region}-installation-data"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/${var.customer}-${var.env}-${var.aws_region}-installation-data/"
  }
  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Deny GetObject without secureTransport",
      "Action": ["s3:GetObject"],
      "Effect": "Deny",
      "Resource": "arn:aws:s3:::${var.customer}-${var.env}-${var.aws_region}-installation-data/*",
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

resource "aws_s3_bucket" "client_root_control_bucket" {
  bucket = "axiom-${var.customer}-${var.env}-root-control"
  acl    = "private"

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
    Name        = "axiom-${var.customer}-${var.env}-root-control"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-root-control/"
  }
  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Deny GetObject without secureTransport",
      "Action": ["s3:GetObject"],
      "Effect": "Deny",
      "Resource": "arn:aws:s3:::axiom-${var.customer}-${var.env}-root-control/*",
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

data "aws_s3_bucket_object" "ec2_ssh_public_key" {
  bucket = "axiom-${var.customer}-${var.env}-root-control"
  key    = "id_rsa.pub"
}

resource "aws_s3_bucket_object" "client-data" {
  bucket = "${var.customer}-${var.env}-${var.aws_region}-installation-data"
  key    = "playbooks.tar.gz"
  source = "temp/playbooks.tar.gz"
  depends_on = [
    null_resource.create-archive,
    aws_s3_bucket.client-bucket,
  ]
  etag = timestamp()
}

resource "null_resource" "create-archive" {
  triggers = {
    x = timestamp()
  }

  provisioner "local-exec" {
    command = "tar -zcf temp/playbooks.tar.gz playbooks"
  }
}

#### permissions - to be transfered to roles.tf
data "aws_iam_policy_document" "client-bucket-policy-doc" {
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.customer}-${var.env}-${var.aws_region}-installation-data",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-archival",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-root-control",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data",
      "arn:aws:s3:::axiom-${var.customer}-01-client-repo",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging",
      aws_s3_bucket.application_logs_bucket.arn,
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-root-control/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-key/${var.customer}-${var.env}-key.pub",
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${var.customer}-${var.env}-${var.aws_region}-installation-data/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-archival/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging/*",
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]
    resources = [
      "arn:aws:s3:::${var.customer}-${var.env}-${var.aws_region}-installation-data/cv-server/*",
      "arn:aws:s3:::${var.customer}-${var.env}-${var.aws_region}-installation-data/ssl/*",
      "arn:aws:s3:::${var.customer}-${var.env}-${var.aws_region}-installation-data/datalineage/*",
      "arn:aws:s3:::axiom-${var.customer}-01-client-repo/*",
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.application_logs_bucket.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "client-bucket-policy" {
  name   = "client-bucket-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.client-bucket-policy-doc.json
}

resource "aws_iam_role_policy_attachment" "tomcat_client_bucket_att" {
  role       = aws_iam_role.tomcat.name
  policy_arn = aws_iam_policy.client-bucket-policy.arn
}

resource "aws_iam_role_policy_attachment" "generic_client_bucket_att" {
  role       = aws_iam_role.generic_ec2_role.name
  policy_arn = aws_iam_policy.client-bucket-policy.arn
}

resource "aws_iam_role_policy_attachment" "cv_client_bucket_att" {
  role       = aws_iam_role.cv_instance_profile.name
  policy_arn = aws_iam_policy.client-bucket-policy.arn
}

# cv data bucket
resource "aws_s3_bucket" "cv-default-data-bucket" {
  bucket = "axiom-${var.customer}-${var.env}-${var.aws_region}-data"
  acl    = "private"

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
    Name        = "axiom-${var.customer}-${var.env}-${var.aws_region}-data"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-${var.aws_region}-data/"
  }
}

resource "aws_s3_bucket" "cv_archive_bucket" {
  bucket        = "axiom-${var.customer}-${var.env}-${var.aws_region}-archival"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    noncurrent_version_transition {
      days          = 30 #min 30 days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 30 #min 30 days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    noncurrent_version_transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }

  lifecycle_rule {
    id      = "cv-live"
    enabled = true
    prefix  = "cv-live/"

    expiration {
      days = var.cv_ui_retention_period
    }
  }

  lifecycle_rule {
    id      = "cv-wf-live"
    enabled = true
    prefix  = "cv-wf-live/"

    expiration {
      days = var.cv_wlog_retention_period
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = {
    Name        = "axiom-${var.customer}-${var.env}-${var.aws_region}-archival"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-${var.aws_region}-archival/"
  }
}

resource "aws_s3_bucket" "cv_filefolder_archive_bucket" {
  bucket        = "axiom-${var.customer}-${var.env}-${var.aws_region}-ff-archive"
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
    Name        = "axiom-${var.customer}-${var.env}-${var.aws_region}-ff-archive"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-${var.aws_region}-ff-archive/"
  }
}

data "aws_s3_bucket" "trigger-s3-ref" {
  bucket     = "axiom-${var.customer}-${var.env}-${var.aws_region}-data"
  depends_on = [aws_s3_bucket.cv-default-data-bucket]
}

# Target: axiom-${var.customer}-${var.env}-${var.aws_region}-data
# Taking advantage for the aws_iam_policy_document to generate a well-formed
# S3 Bucket Policy JSON document
data "aws_iam_policy_document" "cv-default-data-bucket-s3-policy-doc" {
  statement { //End of statement 1
    sid    = "1"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cv_instance_profile.arn, aws_iam_role.tomcat.arn]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  }

  statement { //End of statement 2
    sid    = "2"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cv_instance_profile.arn, aws_iam_role.tomcat.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  }
  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:GetObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "cv-default-data-bucket-s3-policy" {
  bucket = aws_s3_bucket.cv-default-data-bucket.id
  policy = data.aws_iam_policy_document.cv-default-data-bucket-s3-policy-doc.json
}

data "aws_iam_policy_document" "cv_archive_bucket_s3_policy_doc" {
  count = var.enable_cv_archive_via_s3
  statement { //End of statement 1
    sid    = "1"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cv_instance_profile.arn, aws_iam_role.tomcat.arn]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-archival",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  }

  statement { //End of statement 2
    sid    = "2"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cv_instance_profile.arn, aws_iam_role.tomcat.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-archival/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  }
  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:GetObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-archival/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "cv_archive_s3_policy" {
  count  = var.enable_cv_archive_via_s3
  bucket = aws_s3_bucket.cv_archive_bucket.id
  policy = data.aws_iam_policy_document.cv_archive_bucket_s3_policy_doc[0].json
}

data "aws_iam_policy_document" "cv_ff_archive_bucket_s3_policy_doc" {
  statement {
    sid    = "1"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cv_instance_profile.arn, aws_iam_role.tomcat.arn]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-ff-archive",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  } //End of statement 1

  statement {
    sid    = "2"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cv_instance_profile.arn, aws_iam_role.tomcat.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-ff-archive/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  } //End of statement 2
  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:GetObject", ]
    principals {
      type        = "*"
      identifiers = ["*", ]
    }
    condition {
      test     = "Bool"
      values   = ["false", ]
      variable = "aws:SecureTransport"
    }
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-ff-archive/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "cv_ff_archive_s3_policy" {
  bucket     = aws_s3_bucket.cv_filefolder_archive_bucket.id
  policy     = data.aws_iam_policy_document.cv_ff_archive_bucket_s3_policy_doc.json
  depends_on = [aws_s3_bucket_public_access_block.public_block_ff_archive]
}

data "aws_iam_policy_document" "cv-default-data-bucket-policy-doc" {
  statement {
    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data/*",
    ]

    # [AXCL-315]Ntan: IP Address Filtering based on the approved list of allowed source cidr block
    # from the generated / rendered allowed-cidr-blocks.tf from init_tf.py
    condition {
      test     = "ForAnyValue:IpAddress"
      variable = "aws:SourceIp"

      #${var.source_cidr_blocks_allowed}: Axiomsl's Public IP Address temporary added for...
      #Axiomsl's Internal testing.
      #${var.customer_vpn_gtw_ip}: Public IP address for the Customer's VPN Gateway. Use a Link Local IP address if this is empty.
      #${var.customer_internal_cidr_block}: Private IP address CIDR block from Customer's Office.
      #values = ["${var.source_cidr_blocks_allowed}", "${compact(var.customer_vpn_gtw_ip)}"]
      values = var.source_cidr_blocks_allowed
    }
  }

  statement {
    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values   = var.source_vpces_allowed
    }
  }
}

resource "aws_iam_policy" "cv-default-data-bucket-policy" {
  name   = "cv-default-data-bucket-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.cv-default-data-bucket-policy-doc.json
}

# cv key bucket
resource "aws_s3_bucket" "cv-default-key-bucket" {
  bucket = "axiom-${var.customer}-${var.env}-${var.aws_region}-key"
  acl    = "private"

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
    Name        = "axiom-${var.customer}-${var.env}-${var.aws_region}-key"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-${var.aws_region}-key/"
  }
}

# Target: axiom-${var.customer}-${var.env}-${var.aws_region}-key
# Taking advantage for the aws_iam_policy_document to generate a well-formed
# S3 Bucket Policy JSON document
data "aws_iam_policy_document" "cv-default-key-bucket-s3-policy-doc" {
  statement {
    sid    = "1"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cv_instance_profile.arn, aws_iam_role.tomcat.arn]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-key/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  }
  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:GetObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-key/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "cv-default-key-bucket-s3-policy" {
  bucket = aws_s3_bucket.cv-default-key-bucket.id // End of statement 1
  policy = data.aws_iam_policy_document.cv-default-key-bucket-s3-policy-doc.json
}

data "aws_iam_policy_document" "cv-default-key-bucket-policy-doc" {
  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-key/*",
    ]

    # [AXCL-315]Ntan: IP Address Filtering based on the approved list of allowed source cidr block
    # from the generated / rendered allowed-cidr-blocks.tf from init_tf.py
    condition {
      test     = "ForAnyValue:IpAddress"
      variable = "aws:SourceIp"

      #${var.source_cidr_blocks_allowed}: Axiomsl's Public IP Address temporary added for...
      #Axiomsl's Internal testing.
      #${var.customer_vpn_gtw_ip}: Public IP address for the Customer's VPN Gateway.
      #${var.customer_internal_cidr_block}: Private IP address CIDR block from Customer's Office.
      #values = ["${var.source_cidr_blocks_allowed}", "${compact(var.customer_vpn_gtw_ip)}"]
      values = var.source_cidr_blocks_allowed
    }
  }

  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-key/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values   = var.source_vpces_allowed
    }
  }
}

###########add ^^^

resource "aws_iam_policy" "cv-default-key-bucket-policy" {
  name   = "cv-default-key-bucket-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.cv-default-key-bucket-policy-doc.json
}

resource "aws_iam_group_policy_attachment" "cv-default-data-bucket-policy" {
  group      = aws_iam_group.customers.name
  policy_arn = aws_iam_policy.cv-default-data-bucket-policy.arn
}

resource "aws_iam_group_policy_attachment" "cv-default-key-bucket-policy" {
  group      = aws_iam_group.customers.name
  policy_arn = aws_iam_policy.cv-default-key-bucket-policy.arn
}

### Need an elb service in order to enable access logs generation.
data "aws_elb_service_account" "main" {
}

resource "aws_s3_bucket" "client_elb_access_logs_bucket" {
  bucket        = "axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-elb-access-logs"
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
    Name = "axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-elb-access-logs"
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-elb-access-logs"
  }

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow putobject for elb.",
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-elb-access-logs/*",
      "Principal": {
        "AWS": [
          "${data.aws_elb_service_account.main.arn}"
        ]
      }
    },
    {
      "Sid": "Deny GetObject without secureTransport",
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Deny",
      "Resource": "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-elb-access-logs/*",
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

# S3 Bucket for All S3 bucket Logging

data "aws_iam_policy_document" "s3_bucket_logging-policy-document" {
  statement {
    actions   = ["s3:PutObject", "s3:GetObject"]
    effect    = "Allow"
    resources = ["arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-s3-bucket-logging/*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.env_account.account_id}:root"]
    }
  }

  # bucket policy for redshift connection, user, user activity logging
  statement {
    actions   = ["s3:PutObject"]
    effect    = "Allow"
    resources = ["arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-s3-bucket-logging/*"]
    principals {
      identifiers = ["arn:aws:iam::${local.db_audit_accounts[var.aws_region]}:user/logs"]
      type        = "AWS"
    }
  }

  statement {
    actions   = ["s3:GetBucketAcl"]
    effect    = "Allow"
    resources = ["arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-s3-bucket-logging"]
    principals {
      identifiers = ["arn:aws:iam::${local.db_audit_accounts[var.aws_region]}:user/logs"]
      type        = "AWS"
    }
  }
  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:GetObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
    resources = [
      "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-s3-bucket-logging/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "s3_bucket_logging-policy" {
  bucket = aws_s3_bucket.s3_bucket_logging.id
  policy = data.aws_iam_policy_document.s3_bucket_logging-policy-document.json
}

resource "aws_s3_bucket" "s3_bucket_logging" {
  bucket        = "axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-s3-bucket-logging"
  acl           = "log-delivery-write"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-S3-bucket-logging"
  }
}

#### Environment folders for elb access logs and s3 access logs

resource "aws_s3_bucket_object" "env-s3-access-logs" {
  bucket = aws_s3_bucket.s3_bucket_logging.id
  acl    = "private"
  key    = "${var.env}-${var.aws_region}-logs/"
  source = "/dev/null"
}

resource "aws_s3_bucket_object" "env-elb-access-logs" {
  bucket = aws_s3_bucket.client_elb_access_logs_bucket.id
  acl    = "private"
  key    = "${var.env}-${var.aws_region}-logs/"
  source = "/dev/null"
}

# outbound data bucket
resource "aws_s3_bucket" "outbound-data-bucket" {
  count         = var.enable_outbound_transfer == "true" ? 1 : 0
  bucket        = "axiom-${var.customer}-${var.env}-${var.aws_region}-outbound-data"
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
    Name        = "axiom-${var.customer}-${var.env}-${var.aws_region}-outbound-data"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-${var.aws_region}-outbound-data/"
  }
}

# application logs bucket
resource "aws_s3_bucket" "application_logs_bucket" {
  bucket        = "axiom-${var.customer}-${var.env}-${var.aws_region}-application-logs"
  acl           = "private"
  force_destroy = true

  lifecycle_rule {
    id      = "app-log-expiration"
    enabled = "true"

    expiration {
      days = "2"
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = {
    Name        = "axiom-${var.customer}-${var.env}-${var.aws_region}-application-logs"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-${var.aws_region}-application-logs/"
  }
}

resource "aws_s3_bucket" "env_temination_control_bucket" {
  bucket        = "axiom-${var.customer}-${var.env}-termination-control"
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
    Name        = "axiom-${var.customer}-${var.env}-termination-control"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-termination-control/"
  }
  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Deny GetObject without secureTransport",
      "Action": ["s3:GetObject","s3:DeleteObject"],
      "Effect": "Deny",
      "Resource": "arn:aws:s3:::axiom-${var.customer}-${var.env}-termination-control/*",
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

resource "aws_s3_bucket_object" "termination_control_key" {
  count      = var.jenkins_env == "production" ? 1 : 0
  bucket     = "axiom-${var.customer}-${var.env}-termination-control"
  key        = "disable-termination"
  depends_on = [aws_s3_bucket.env_temination_control_bucket]
}

resource "aws_s3_bucket_public_access_block" "public_block_termination" {
  bucket                  = aws_s3_bucket.env_temination_control_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "public_block_client" {
  bucket                  = aws_s3_bucket.client-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "public_block_root" {
  bucket                  = aws_s3_bucket.client_root_control_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "public_block_archive" {
  count                   = var.enable_cv_archive_via_s3
  bucket                  = aws_s3_bucket.cv_archive_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "public_block_ff_archive" {
  bucket                  = aws_s3_bucket.cv_filefolder_archive_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.cv_filefolder_archive_bucket]
}

resource "aws_s3_bucket_public_access_block" "public_block_cvkey" {
  bucket                  = aws_s3_bucket.cv-default-key-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "public_block_elblogs" {
  bucket                  = aws_s3_bucket.client_elb_access_logs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "public_block_bucketlogs" {
  bucket                  = aws_s3_bucket.s3_bucket_logging.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "public_block_ff_reporting" {
  bucket                  = aws_s3_bucket.cv_filefolder_reporting_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.cv_filefolder_reporting_bucket]
}

# CV WORM data bucket
resource "aws_s3_bucket" "cv-worm-data-bucket" {
  count  = var.enable_worm_compliance == "true" ? 1 : 0
  bucket = "axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data"
  acl    = "private"

  //etag   = "${md5("../cis/axiom-cis.yaml")}" //This attribute is not compatible with KMS encryption

  versioning {
    enabled = true
  }

  object_lock_configuration {
    object_lock_enabled = "Enabled"
    rule {
      default_retention {
        mode = "COMPLIANCE"
        days = var.worm_compliance_days
      }
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = {
    Name        = "axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data/"
  }
}

data "aws_iam_policy_document" "cv-worm-data-bucket-s3-policy-doc" {
  count = var.enable_worm_compliance == "true" ? 1 : 0
  statement { //End of statement 1
    sid    = "1"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cv_instance_profile.arn, aws_iam_role.tomcat.arn]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  }

  statement { //End of statement 2
    sid    = "2"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cv_instance_profile.arn, aws_iam_role.tomcat.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  }
  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:GetObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "cv-worm-data-bucket-s3-policy" {
  count  = var.enable_worm_compliance == "true" ? 1 : 0
  bucket = aws_s3_bucket.cv-worm-data-bucket[0].id
  policy = data.aws_iam_policy_document.cv-worm-data-bucket-s3-policy-doc[0].json
}

data "aws_s3_bucket" "trigger-worm-s3-ref" {
  count      = var.enable_worm_compliance == "true" ? 1 : 0
  bucket     = "axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data"
  depends_on = [aws_s3_bucket.cv-worm-data-bucket]
}

resource "aws_iam_group_policy_attachment" "cv-default-worm-data-bucket-policy" {
  count      = var.enable_worm_compliance == "true" ? 1 : 0
  group      = aws_iam_group.customers.name
  policy_arn = aws_iam_policy.cv-default-worm-data-bucket-policy[0].arn
}

data "aws_iam_policy_document" "cv-default-worm-data-bucket-policy-doc" {
  count = var.enable_worm_compliance == "true" ? 1 : 0
  statement {
    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data/*",
    ]

    # [AXCL-315]Ntan: IP Address Filtering based on the approved list of allowed source cidr block
    # from the generated / rendered allowed-cidr-blocks.tf from init_tf.py
    condition {
      test     = "ForAnyValue:IpAddress"
      variable = "aws:SourceIp"

      #${var.source_cidr_blocks_allowed}: Axiomsl's Public IP Address temporary added for...
      #Axiomsl's Internal testing.
      #${var.customer_vpn_gtw_ip}: Public IP address for the Customer's VPN Gateway. Use a Link Local IP address if this is empty.
      #${var.customer_internal_cidr_block}: Private IP address CIDR block from Customer's Office.
      #values = ["${var.source_cidr_blocks_allowed}", "${compact(var.customer_vpn_gtw_ip)}"]
      values = var.source_cidr_blocks_allowed
    }
  }
  # VPCE start
  statement {
    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values   = var.source_vpces_allowed
    }
  }
}

resource "aws_iam_policy" "cv-default-worm-data-bucket-policy" {
  count  = var.enable_worm_compliance == "true" ? 1 : 0
  name   = "cv-default-worm-data-bucket-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.cv-default-worm-data-bucket-policy-doc[0].json
}

resource "aws_s3_bucket_public_access_block" "public_block_applogs" {
  bucket                  = aws_s3_bucket.application_logs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "cv_filefolder_reporting_bucket" {
  #count = var.s3_archive_filefolder ? 1 : 0
  bucket        = "axiom-${var.customer}-${var.env}-${var.aws_region}-reporting-files"
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
    Name        = "axiom-${var.customer}-${var.env}-${var.aws_region}-reporting-files"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-${var.aws_region}-reporting-files/"
  }
}

data "aws_iam_policy_document" "cv_ff_reporting_bucket_s3_policy_doc" {
  statement {
    sid    = "1"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cv_instance_profile.arn, aws_iam_role.tomcat.arn]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-reporting-files",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  } //End of statement 1

  statement {
    sid    = "2"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cv_instance_profile.arn, aws_iam_role.tomcat.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-reporting-files/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  } //End of statement 2
  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:GetObject", ]
    principals {
      type        = "*"
      identifiers = ["*", ]
    }
    condition {
      test     = "Bool"
      values   = ["false", ]
      variable = "aws:SecureTransport"
    }
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-reporting-files/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "cv_ff_reporting_s3_policy" {
  bucket     = aws_s3_bucket.cv_filefolder_reporting_bucket.id
  policy     = data.aws_iam_policy_document.cv_ff_reporting_bucket_s3_policy_doc.json
  depends_on = [aws_s3_bucket_public_access_block.public_block_ff_reporting]
}

resource "aws_s3_bucket" "env_cw_export_task_logs_bucket" {
  bucket        = "axiom-${var.customer}-${var.env}-${var.aws_region}-cw-export-logs"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "axiom-${var.customer}-${var.env}-${var.aws_region}-cw-export-logs"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-${var.aws_region}-cw-export-logs"
  }
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "Policy",
    "Statement": [
        {
            "Sid": "Allow CW to execute export task",
            "Effect": "Allow",
            "Principal": {
                "Service": "logs.${var.aws_region}.amazonaws.com"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-cw-export-logs"
        },
        {
            "Sid": "Allow CW to execute export task",
            "Effect": "Allow",
            "Principal": {
                "Service": "logs.${var.aws_region}.amazonaws.com"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-cw-export-logs/*"
        }
    ]
}
POLICY

}

resource "aws_s3_bucket_public_access_block" "env_cw_export_task_logs_bucket" {
  bucket                  = aws_s3_bucket.env_cw_export_task_logs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "emr_execution_internals_bucket" {
  count         = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  bucket        = "axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-internals"
  acl           = "private"
  force_destroy = true
  versioning {
    enabled = false
  }
  lifecycle_rule {
    enabled = true
    expiration {
      days = 1
    }
    noncurrent_version_expiration {
      days = 1
    }
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.emr_staging[0].id
      }
      bucket_key_enabled = true
    }
  }

  tags = {
    Name        = "axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-internals"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-internals/"
  }
}

resource "aws_s3_bucket_public_access_block" "emr_execution_internals_bucket" {
  count                   = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  bucket                  = aws_s3_bucket.emr_execution_internals_bucket[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "emr_execution_staging_bucket" {
  count         = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  bucket        = "axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging"
  acl           = "private"
  force_destroy = true
  versioning {
    enabled = false
  }
  lifecycle_rule {
    enabled = true
    expiration {
      days = 1
    }
    noncurrent_version_expiration {
      days = 1
    }
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.emr_staging[0].id
      }
      bucket_key_enabled = true
    }
  }

  tags = {
    Name        = "axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging/"
  }
}

resource "aws_s3_bucket_public_access_block" "emr_execution_staging_bucket" {
  count                   = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  bucket                  = aws_s3_bucket.emr_execution_staging_bucket[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# emr-execution-data bucket with disabled SSE since itd data itself is encrypted using CSE kms key
resource "aws_s3_bucket" "emr_execution_data_bucket" {
  count         = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  bucket        = "axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-data"
  acl           = "private"
  force_destroy = true
  versioning {
    enabled = true
  }
  lifecycle_rule {
    enabled = true
    noncurrent_version_transition {
      days          = 30 #min 30 days
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 30 #min 30 days
      storage_class = "STANDARD_IA"
    }
  }

  tags = {
    Name        = "axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-data"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-data/"
  }
}

resource "aws_s3_bucket_public_access_block" "emr_execution_data_bucket" {
  count                   = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  bucket                  = aws_s3_bucket.emr_execution_data_bucket[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# execution data EMR S3 bucket accessed by Spark EMR cluster
data "aws_iam_policy_document" "emr_execution_data_bucket_policy_doc" {
  count = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-data/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "emr_execution_data_bucket_policy" {
  count  = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  bucket = aws_s3_bucket.emr_execution_data_bucket[0].id
  policy = data.aws_iam_policy_document.emr_execution_data_bucket_policy_doc[0].json
}

# execution staging EMR S3 bucket accessed by CV app server
data "aws_iam_policy_document" "emr_execution_staging_bucket_policy_doc" {
  count = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  statement { //End of statement 1
    sid    = "1"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cv_instance_profile.arn, aws_iam_role.tomcat.arn]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  }

  statement { //End of statement 2
    sid    = "2"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cv_instance_profile.arn, aws_iam_role.tomcat.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  }
  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:GetObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "emr_execution_staging_bucket_policy" {
  count  = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  bucket = aws_s3_bucket.emr_execution_staging_bucket[0].id
  policy = data.aws_iam_policy_document.emr_execution_staging_bucket_policy_doc[0].json
}

# execution internals EMR S3 bucket accessed by CV app server
data "aws_iam_policy_document" "emr_execution_internals_bucket_policy_doc" {
  count = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  statement { //End of statement 1
    sid    = "1"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cv_instance_profile.arn, aws_iam_role.tomcat.arn]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-internals",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  }

  statement { //End of statement 2
    sid    = "2"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cv_instance_profile.arn, aws_iam_role.tomcat.arn]
    }

    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-internals/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.s3.id]
    }
  }
  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:GetObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-internals/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "emr_execution_internals_bucket_policy" {
  count  = var.enable_spark == "true" || var.keep_spark_data == "true" ? 1 : 0
  bucket = aws_s3_bucket.emr_execution_internals_bucket[0].id
  policy = data.aws_iam_policy_document.emr_execution_internals_bucket_policy_doc[0].json
}

resource "aws_iam_group_policy_attachment" "sftp-transfer-policy-att" {
  count      = var.enable_sftp_transfer == "true" ? 1 : 0
  group      = aws_iam_group.sftptransfer[0].name
  policy_arn = aws_iam_policy.sftp-transfer-data-bucket-policy[0].arn
}

resource "aws_iam_policy" "sftp-transfer-data-bucket-policy" {
  count  = var.enable_sftp_transfer == "true" ? 1 : 0
  name   = "sftp-transfer-data-bucket-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.sftp-transfer-data-bucket-policy-doc[0].json
}

data "aws_iam_policy_document" "sftp-transfer-data-bucket-policy-doc" {
  count = var.enable_sftp_transfer == "true" ? 1 : 0
  # Statement #1
  statement {
    sid     = "AllowListDataBucket"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data",
    ]

    condition {
      test     = "ForAnyValue:IpAddress"
      variable = "aws:SourceIp"
      values   = compact(split(",", var.web_proxy_nat_eips_mft_region))
    }
  }

  # Statement #2
  statement {
    sid    = "AllowAccessObjects"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data/*",
    ]

    condition {
      test     = "ForAnyValue:IpAddress"
      variable = "aws:SourceIp"
      values   = compact(split(",", var.web_proxy_nat_eips_mft_region))
    }
  }

  # Statement #3
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt"
    ]
    resources = ["arn:aws:kms:*:*:key/*"]

    condition {
      test     = "ForAnyValue:IpAddress"
      variable = "aws:SourceIp"
      values   = compact(split(",", var.web_proxy_nat_eips_mft_region))
    }
  }
}

#Monitoring User policy
resource "aws_iam_group_policy_attachment" "data_bucket_monitoring_policy_att" {
  group      = aws_iam_group.monitoring.name
  policy_arn = aws_iam_policy.data_bucket_monitoring_policy.arn
}

resource "aws_iam_policy" "data_bucket_monitoring_policy" {
  name   = "data-bucket-monitoring-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.data_bucket_monitoring_policy_doc.json
}

data "aws_iam_policy_document" "data_bucket_monitoring_policy_doc" {
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data",
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
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values   = var.source_vpces_allowed
    }
  }
}
