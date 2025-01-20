# Redshift module inclusions here with Redshift database as a User DBSource
# reuse RDS convention and database password
module "redshift" {
  # TF-UPGRADE-TODO: In Terraform v0.11 and earlier, it was possible to
  # reference a relative module source without a preceding ./, but it is no
  # longer supported in Terraform v0.12.
  #
  # If the below module source is indeed a relative local path, add ./ to the
  # start of the source string. If that is not the case, then leave it as-is
  # and remove this TODO comment.
  source                              = "./modules/terraform-aws-redshift"
  customer                            = var.customer
  env                                 = var.env
  # source  = "terraform-aws-modules/redshift/aws"
  # version = "~> 2.0"
  #version = "1.7.0"
  # source  = "terraform-aws-modules/redshift/aws"
  # version = "~> 2.0"

  # insert the 6 required variables here
  cluster_database_name               = var.cluster_database_name
  cluster_identifier                  = "${var.cluster_identifier}-${var.customer}-${var.env}"
  cluster_master_password             = data.aws_ssm_parameter.database_password.value
  cluster_master_username             = var.cluster_master_username
  cluster_node_type                   = var.cluster_node_type
  allow_version_upgrade               = "false"
  automated_snapshot_retention_period = "7"
  cluster_iam_roles                   =  var.enable_redshift == "true" ? [aws_iam_role.redshift_role[0].arn] : []
  cluster_parameter_group             = "redshift-1.0" # defaulted value
  cluster_port                        = var.cluster_port
  cluster_version                     = "1.0" # defaulted value
  cluster_number_of_nodes             = var.cluster_number_of_nodes
  enable_logging                      = "true"
  enable_user_activity_logging        = "true"
  encrypted                           = "true"
  enhanced_vpc_routing                = "true"
  final_snapshot_identifier           = "${var.cluster_identifier}-${var.customer}-${var.env}-final-snapshot-${substr(uuid(), 0, 8)}"
  kms_key_id                          = var.enable_byok == "true" ? data.aws_kms_alias.rds_fortanix_key[0].target_key_arn : aws_kms_key.rds[0].arn
  logging_bucket_name                 = aws_s3_bucket.s3_bucket_logging.id
  logging_s3_key_prefix               = "${var.env}-${var.aws_region}-redshift-logs/"
  #parameter_group_name               = "" # let terraform module create it
  preferred_maintenance_window        = "sat:10:00-sat:10:30"
  publicly_accessible                 = "false"
  #redshift_subnet_group_name         = "" # let terraform module create it
  require_ssl                         = "true"
  skip_final_snapshot                 = "false"
  subnets                             = [aws_subnet.data_a.id, aws_subnet.data_b.id]
  lambda_subnet_ids                   = [aws_subnet.app_a.id, aws_subnet.app_b.id]
  vpc_security_group_ids              = [aws_security_group.redshift_sg.id]
  enable_redshift                     = var.enable_redshift
  wlm_json_configuration              = var.wlm_json_config
  db_hostname_rs                      = module.redshift.this_redshift_cluster_hostname
  lambda_security_group_id            = aws_security_group.run_query_rs_lambda_security_group.id
  aws_region                          = var.aws_region
}

resource "aws_security_group" "redshift_sg" {
  name        = "${var.aws_region}-${var.customer}-${var.env}-redshift"
  description = "Redshift cluster security group."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-redshift"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

# Redshift Ingress from CV
resource "aws_security_group_rule" "redshift_ingress_1" {
  description              = "Allows inbound traffic from cv"
  from_port                = var.cluster_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.redshift_sg.id
  to_port                  = var.cluster_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.cv.id
}

# Redshift Ingress from Tomcat
resource "aws_security_group_rule" "redshift_ingress_2" {
  description              = "Allows inbound traffic from tomcat"
  from_port                = var.cluster_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.redshift_sg.id
  to_port                  = var.cluster_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.tomcat.id
}

# Redshift Egress to s3
resource "aws_security_group_rule" "redshift_egress_1" {
  description       = "Allows outbound traffic from redshift for s3 access via s3 endpoint"
  from_port         = "443"
  protocol          = "tcp"
  security_group_id = aws_security_group.redshift_sg.id
  to_port           = "443"
  type              = "egress"
  prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
}

resource "aws_security_group_rule" "redshift_egress_2" {
  count                     = var.enable_redshift == "true" ? 1 : 0
  description              = "Allows Redshift reach to glue private end point."
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.redshift_sg.id
  to_port                  = 443
  type                     = "egress"
  source_security_group_id = aws_security_group.private_endpoints.id
}



# SG to allow run-query-rs Lambda to run sql commands on RDS
resource "aws_security_group" "run_query_rs_lambda_security_group" {
  name                     = "${var.aws_region}-${var.customer}-${var.env}-run-query-rs-lambda"
  description              = "AWS Lambda run-query-rs security group."
  vpc_id                   = aws_vpc.main.id

  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-lambda-run-query-rs"
    region   = var.business_region[var.aws_region]
    customer = var.customer
  }
}

resource "aws_security_group_rule" "run_query_rs_lambda_sg_egress_1" {
  description              = "Outbound traffic from Lambda to Redshift cluster"
  from_port                = var.cluster_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.run_query_rs_lambda_security_group.id
  to_port                  = var.cluster_port
  type                     = "egress"
  source_security_group_id = aws_security_group.redshift_sg.id
}

resource "aws_security_group_rule" "run_query_rs_lambda_sg_egress_2" {
  description              = "Allows run_query_rs Lambda to reach the SSM end point."
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.run_query_rs_lambda_security_group.id
  to_port                  = 443
  type                     = "egress"
  source_security_group_id = aws_security_group.private_endpoints.id
}

# Redshift Ingress from run query rs lambda
resource "aws_security_group_rule" "redshift_ingress_3" {
  description              = "Allows inbound traffic from run_query_rs Lambda"
  from_port                = var.cluster_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.redshift_sg.id
  to_port                  = var.cluster_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.run_query_rs_lambda_security_group.id
}

resource "aws_s3_bucket" "redshift_temp_bucket" {
  count         = var.enable_redshift == "true" ? 1 : 0
  bucket        = "axiom-${var.customer}-${var.env}-${var.aws_region}-temp-redshift"
  acl           = "private"
  force_destroy = true

  tags = {
    Name        = "axiom-${var.customer}-${var.env}-${var.aws_region}-temp-redshift"
    Environment = var.env
    Customer    = var.customer
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-${var.aws_region}-temp-redshift/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket" "cv_redshift_pre_archival_bucket" {
  count   = var.enable_redshift == "true" ? 1 : 0
  bucket  = "axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival"
  acl     = "private"

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
    Name        = "axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival"
    Environment = var.env
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival/"
  }
}

data "aws_iam_policy_document" "redshift_temp_bucket_s3_policy_doc" {
  count = var.enable_redshift == "true" ? 1 : 0
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
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-temp-redshift",
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
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-temp-redshift/*",
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
    actions = ["s3:GetObject"]
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
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-temp-redshift/*",
    ]
  }
}

data "aws_iam_policy_document" "redshift_pre_archival_bucket_s3_policy_doc" {
  count = var.enable_redshift == "true" ? 1 : 0
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
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival"
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
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival/*"
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
    actions = ["s3:GetObject"]
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
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival/*"
    ]
  }
}
resource "aws_s3_bucket_policy" "redshift_temp_bucket_s3_policy" {
  count  = var.enable_redshift == "true" ? 1 : 0
  bucket = aws_s3_bucket.redshift_temp_bucket[0].id
  policy = data.aws_iam_policy_document.redshift_temp_bucket_s3_policy_doc[0].json
}

resource "aws_s3_bucket_policy" "cv_redshift_pre_archival_bucket_s3_policy" {
  count  = var.enable_redshift == "true" ? 1 : 0
  bucket = aws_s3_bucket.cv_redshift_pre_archival_bucket[0].id
  policy = data.aws_iam_policy_document.redshift_pre_archival_bucket_s3_policy_doc[0].json
}