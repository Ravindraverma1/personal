##############################################################################
#  EC2 generic profile and role for the profile
##############################################################################

resource "aws_iam_instance_profile" "generic" {
  name = "app-profile-${var.customer}-${var.env}"
  role = aws_iam_role.generic_ec2_role.id
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "generic_ec2_role" {
  name               = "generic-${var.customer}-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

##############################################################################
#  CV Instance profile and role
##############################################################################

resource "aws_iam_instance_profile" "cv" {
  name = "cv_profile-${var.customer}-${var.env}"
  role = aws_iam_role.cv_instance_profile.id
}

resource "aws_iam_role" "cv_instance_profile" {
  name               = "cv-${var.customer}-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "cv_metrics_cloudwatch_att" {
  role       = aws_iam_role.cv_instance_profile.name
  policy_arn = aws_iam_policy.ec2_metrics_cloudwatch_policy.arn
}

resource "aws_iam_role_policy_attachment" "cv_events_policy_att" {
  role       = aws_iam_role.cv_instance_profile.name
  policy_arn = aws_iam_policy.cv_events_policy.arn
}

data "aws_iam_policy_document" "ses_recipient_policy_document" {
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

data "aws_iam_policy_document" "cv_kms_policy_doc" {
  statement {
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:ReEncrypt*",
      "kms:Encrypt",
      "kms:CreateGrant",
    ]
    resources = [
      aws_kms_key.ssm.arn,
    ]
  }
}

resource "aws_iam_policy" "ses_recipient_policy" {
  name   = "ses_recipient_policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.ses_recipient_policy_document.json
}

resource "aws_iam_role_policy_attachment" "ses_recipient_cv_att" {
  role       = aws_iam_role.cv_instance_profile.name
  policy_arn = aws_iam_policy.ses_recipient_policy.arn
}

resource "aws_iam_policy" "cv_kms_policy" {
  name   = "cv_kms_policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.cv_kms_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "cv_kms_policy_attch" {
  role       = aws_iam_role.cv_instance_profile.name
  policy_arn = aws_iam_policy.cv_kms_policy.arn
}

##
# SSM Parameter Store
##
data "aws_iam_policy_document" "ssm_parameter_store_document_saas" {
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]

    resources = [
      "arn:aws:ssm:${var.aws_region}:*:parameter/${var.customer}/${var.env}/*",
    ]
  }

  statement {
    actions = [
      "kms:Decrypt",
    ]

    resources = [
      aws_kms_key.ssm.arn,
    ]
  }
}

data "aws_iam_policy_document" "ssm_parameter_store_document_di" {
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]

    resources = [
      "arn:aws:ssm:${var.aws_region}:*:parameter/${var.customer}/${var.env}/*",
      "arn:aws:ssm:${var.aws_region}:*:parameter/${var.saas_customer}/${var.saas_env}/*",
    ]
  }

  statement {
    actions = [
      "kms:Decrypt",
    ]

    resources = [
      "arn:aws:kms:${var.aws_region}:*:key/*",
    ]
  }
}

resource "aws_iam_policy" "ssm_parameter_store" {
  name   = "ssm-get-param-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = var.service_type == "di" ? data.aws_iam_policy_document.ssm_parameter_store_document_di.json : data.aws_iam_policy_document.ssm_parameter_store_document_saas.json
}

resource "aws_iam_role_policy_attachment" "ssm_parameter_store_att" {
  role       = aws_iam_role.generic_ec2_role.name
  policy_arn = aws_iam_policy.ssm_parameter_store.arn
}

resource "aws_iam_role_policy_attachment" "cv_ssm_parameter_store_att" {
  role       = aws_iam_role.cv_instance_profile.name
  policy_arn = aws_iam_policy.ssm_parameter_store.arn
}

resource "aws_iam_role_policy_attachment" "cv_ssm_session_man_att" {
  count      = var.jenkins_env == "development" ? 1 : 0
  role       = aws_iam_role.cv_instance_profile.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

##
# Policy allowing generic instance profile role and Tomcat instance profile
# role to push Disk and Memory metric to Cloudwatch.
##
data "aws_iam_policy_document" "ec2_metrics_cloudwatch_document" {
  statement {
    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeTags",
    ]
    resources = [
      "*",
    ] # Can not be define by ARN 
  }
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:log-group:*:log-stream:*",
    ]
  }
}

resource "aws_iam_policy" "ec2_metrics_cloudwatch_policy" {
  name   = "ec2-metrics-cloudwatch-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.ec2_metrics_cloudwatch_document.json
}

resource "aws_iam_role_policy_attachment" "generic_ec2_metrics_cloudwatch_att" {
  role       = aws_iam_role.generic_ec2_role.name
  policy_arn = aws_iam_policy.ec2_metrics_cloudwatch_policy.arn
}

resource "aws_iam_role_policy_attachment" "generic_ssm_session_man_att" {
  count      = var.jenkins_env == "development" ? 1 : 0
  role       = aws_iam_role.generic_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#
# Policy allowing CV instance to send Rollover events to launching Fargate tasks
#
data "aws_iam_policy_document" "cv_events_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "events:PutEvents",
    ]
    resources = [
      "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:event-bus/default",
    ]
  }
}

resource "aws_iam_policy" "cv_events_policy" {
  name   = "cv_events_policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.cv_events_policy_doc.json
}

###
# Tomcat instance role
###
data "aws_iam_policy_document" "tc_asg_policy_document" {
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingInstances",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "asg_policy" {
  name   = "tc_asg_policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.tc_asg_policy_document.json
}

resource "aws_iam_role" "tomcat" {
  name               = "tomcat-${var.customer}-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "tomcat_ec2_metrics_cloudwatch_att" {
  role       = aws_iam_role.tomcat.name
  policy_arn = aws_iam_policy.ec2_metrics_cloudwatch_policy.arn
}

resource "aws_iam_role_policy_attachment" "ses_recipient_tomcat_att" {
  role       = aws_iam_role.tomcat.name
  policy_arn = aws_iam_policy.ses_recipient_policy.arn
}

resource "aws_iam_role_policy_attachment" "asg_tomcat_att" {
  role       = aws_iam_role.tomcat.name
  policy_arn = aws_iam_policy.asg_policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm_session_man_tomcat_att" {
  count      = var.jenkins_env == "development" ? 1 : 0
  role       = aws_iam_role.tomcat.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "tomcat" {
  name = "tomcat-profile-${var.customer}-${var.env}"
  role = aws_iam_role.tomcat.id
}

#
# RDS Enhanced Monitoring Role.
#
data "aws_iam_role" "created_rds_enhance_mon_role" {
  count = var.toggle_enhance_monitr
  name  = "axiomsl-rds-enhance-monitoring-role"
}

###### Flow Log
resource "aws_iam_role" "vpc_flow_role" {
  name = "${var.customer}_${var.env}_vpc_flow_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "vpc_flow_policy" {
  name = "${var.customer}_${var.env}_vpc_flow_policy"
  role = aws_iam_role.vpc_flow_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource":  "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:log-group:*"
    }
  ]
}
EOF

}

resource "aws_iam_role" "aws_support_role" {
  name               = "aws-support-${var.customer}_${var.env}_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_caller_identity.env_account.account_id}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "support_role_att" {
  role       = aws_iam_role.aws_support_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSupportAccess"
}

###### DI policy
data "aws_iam_policy_document" "cv-saas-access-policy" {
  count = var.service_type == "di" ? 1 : 0
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.saas_customer}-${var.saas_env}-${var.aws_region}-key/",
      "arn:aws:s3:::axiom-${var.saas_customer}-${var.saas_env}-${var.aws_region}-data/",
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.saas_customer}-${var.saas_env}-${var.aws_region}-key/*",
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.saas_customer}-${var.saas_env}-${var.aws_region}-data/*",
    ]
  }
}

resource "aws_iam_policy" "cv-di-saas-policy" {
  count  = var.service_type == "di" ? 1 : 0
  name   = "di-saas-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.cv-saas-access-policy[0].json
}

resource "aws_iam_role_policy_attachment" "di-saas_cv_att" {
  count      = var.service_type == "di" ? 1 : 0
  role       = aws_iam_role.cv_instance_profile.name
  policy_arn = aws_iam_policy.cv-di-saas-policy[0].arn
}

###### outbound transfer policy
data "aws_iam_policy_document" "outbound-transfer-internal-policy" {
  count = var.enable_outbound_transfer == "true" ? 1 : 0
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.outbound-data-bucket[0].arn,
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]

    resources = [
      "${aws_s3_bucket.outbound-data-bucket[0].arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.cv-default-key-bucket.arn}/${var.customer}-${var.env}-outbound-key.pub",
    ]
  }
}

resource "aws_iam_policy" "outbound-transfer-internal-policy" {
  count  = var.enable_outbound_transfer == "true" ? 1 : 0
  name   = "outbound-transfer-internal-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.outbound-transfer-internal-policy[0].json
}

resource "aws_iam_role_policy_attachment" "outbound-transfer-internal-policy-att" {
  count      = var.enable_outbound_transfer == "true" ? 1 : 0
  role       = aws_iam_role.cv_instance_profile.name
  policy_arn = aws_iam_policy.outbound-transfer-internal-policy[0].arn
}

# Policy for redshift to access other AWS services e.g. S3 loading
data "aws_iam_policy_document" "redshift_assume" {
  count = var.enable_redshift == "true" ? 1 : 0
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["redshift.amazonaws.com"]
    }
  }
}

# Policy for redshift to access other AWS services e.g. S3 loading
data "aws_iam_policy_document" "redshift_s3_glue" {
  count = var.enable_redshift == "true" ? 1 : 0
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival",
    ]
  }

  statement {
    actions = ["s3:Get*" , "s3:PutObject"]
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival/*",
    ]
  }

  statement {
    actions = ["kms:Encrypt" , "kms:Decrypt"]
    resources = [
      "arn:aws:kms:*:*:key/*",
    ]
  }

  statement {
    actions = ["glue:CreateDatabase",
      "glue:DeleteDatabase",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:UpdateDatabase",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:BatchDeleteTable",
      "glue:UpdateTable",
      "glue:GetTable",
      "glue:GetTables",
      "glue:BatchCreatePartition",
      "glue:CreatePartition",
      "glue:DeletePartition",
      "glue:BatchDeletePartition",
      "glue:UpdatePartition",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition"]
    resources = [
      "*",
    ]
  }
}
# redshift users get assigned this role
resource "aws_iam_role" "redshift_role" {
  count              = var.enable_redshift == "true" ? 1 : 0
  name               = "redshift-${var.customer}-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.redshift_assume[0].json
}

resource "aws_iam_policy" "redshift_s3_glue_policy" {
  count  = var.enable_redshift == "true" ? 1 : 0
  name   = "redshift-spectrum-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.redshift_s3_glue[0].json
}
resource "aws_iam_role_policy_attachment" "redshift_s3_glue_att" {
  count      = var.enable_redshift == "true" ? 1 : 0
  role       = aws_iam_role.redshift_role[0].name
  policy_arn = aws_iam_policy.redshift_s3_glue_policy[0].arn
}


###### outbound transfer WORM policy
data "aws_iam_policy_document" "outbound-transfer-worm-internal-policy" {
  count = var.enable_worm_compliance == "true" ? 1 : 0
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.cv-worm-data-bucket[0].arn,
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]

    resources = [
      "${aws_s3_bucket.cv-worm-data-bucket[0].arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.cv-default-key-bucket.arn}/${var.customer}-${var.env}-outbound-key.pub",
    ]
  }
}

resource "aws_iam_policy" "outbound-transfer-worm-internal-policy" {
  count  = var.enable_worm_compliance == "true" ? 1 : 0
  name   = "outbound-transfer-worm-internal-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.outbound-transfer-worm-internal-policy[0].json
}

resource "aws_iam_role_policy_attachment" "outbound-transfer-worm-internal-policy-att" {
  count      = var.enable_worm_compliance == "true" ? 1 : 0
  role       = aws_iam_role.cv_instance_profile.name
  policy_arn = aws_iam_policy.outbound-transfer-worm-internal-policy[0].arn
}

# provide an invoke lambda role
data "aws_iam_policy_document" "cross_cv_assume_policy" {
  statement {
    sid = ""
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    # terraform will remove any duplicates account IDs
    principals {
      type        = "AWS"
      identifiers = [for m in local.principals : format("arn:aws:iam::%s:root", lookup(m, "environment_account_id", null))]
    }
  }
}

data "aws_iam_policy_document" "cross_acct_events_role_policy" {
  count = length(distinct(local.cross_acct_principals)) == 1 ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cross_acct_put_events_policy" {
  count = length(distinct(local.cross_acct_principals)) == 1 ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "events:PutEvents",
    ]
    resources = [
      "arn:aws:events:${var.aws_region}:${distinct(local.cross_acct_principals)[0]}:event-bus/default",
    ]
  }
}

resource "aws_iam_policy" "cross_acct_put_events_policy" {
  count  = length(distinct(local.cross_acct_principals)) == 1 ? 1 : 0
  name   = "cross_acct_put_events_policy-${var.customer}-${var.env}"
  path   = "/"
  policy = data.aws_iam_policy_document.cross_acct_put_events_policy[0].json
}

resource "aws_iam_role" "cross_cv_lambda_role" {
  name               = "cross_cv_lambda_role-${var.customer}-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.cross_cv_assume_policy.json
}

resource "aws_iam_role" "cross_acct_event_role" {
  count              = length(distinct(local.cross_acct_principals)) == 1 ? 1 : 0
  name               = "cross_acct_event_role-${var.customer}-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.cross_acct_events_role_policy[0].json
}

resource "aws_iam_role_policy_attachment" "cross_cv_lambdarole_policy_att" {
  role       = aws_iam_role.cross_cv_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

resource "aws_iam_role_policy_attachment" "cross_cv_putevents_policy_att" {
  count      = length(distinct(local.cross_acct_principals)) == 1 ? 1 : 0
  role       = aws_iam_role.cross_acct_event_role[0].name
  policy_arn = aws_iam_policy.cross_acct_put_events_policy[0].arn
}

# Axiom Spark Gateway EMR Role Scaling policy
data "aws_iam_policy_document" "emr_policy_doc" {
  count      = var.enable_spark == "true" ? 1 : 0
  statement {
    actions = [
      "elasticmapreduce:GetManagedScalingPolicy",
      "elasticmapreduce:PutManagedScalingPolicy",
      "elasticmapreduce:ModifyInstanceGroups",
    ]

    resources = [
      "arn:aws:elasticmapreduce:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:cluster/*"
    ]
  }

  statement {
    actions = [
      "glue:BatchDeleteTable",
      "glue:BatchDeletePartition",
      "glue:BatchGetPartition",
    ]

    resources = [
      "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:table/${local.glue_db_name}/*",
      "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:database/${local.glue_db_name}",
      "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:catalog",
    ]
  }
}

resource "aws_iam_policy" "emr_policy" {
  count       = var.enable_spark == "true" ? 1 : 0
  name        = "emr-scaling-adjustments-policy-${var.customer}-${var.env}"
  description = "Policy used by script that modify scaling on start/stop engine"
  path        = "/"
  policy      = data.aws_iam_policy_document.emr_policy_doc[0].json
}

resource "aws_iam_role_policy_attachment" "spark_thrift_role_policy_attach" {
  count      = var.enable_spark == "true" ? 1 : 0
  role       = module.thrift_emr_cluster.ec2_role
  policy_arn = aws_iam_policy.emr_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "spark_exe_role_policy_attach" {
  count      = var.enable_spark == "true" ? 1 : 0
  role       = module.exe_emr_cluster.ec2_role
  policy_arn = aws_iam_policy.emr_policy[0].arn
}

locals {
  self_principal = [{
      environment_name = var.env
      environment_account_id = data.aws_caller_identity.env_account.account_id
  }]
  principals = concat(local.self_principal, var.higher_environments, var.lower_environments)
}

data "aws_iam_policy_document" "default_s3filefolder_policy_doc_saas" {
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
    ]

    resources = [
      "arn:aws:kms:*:*:key/*",
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-key/*",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-ff-archive",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-temp-redshift",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-reporting-files",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-internals",
    ]
    #  "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-archival",
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-ff-archive/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-temp-redshift/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-reporting-files/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-internals/*",
    ]
    # "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-archival/*",
  }
}

data "aws_iam_policy_document" "default_s3filefolder_policy_doc_di" {
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
    ]

    resources = [
      "arn:aws:kms:*:*:key/*",
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-key/*",
      "arn:aws:s3:::axiom-${var.saas_customer}-${var.saas_env}-${var.aws_region}-key/*",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data",
      "arn:aws:s3:::axiom-${var.saas_customer}-${var.saas_env}-${var.aws_region}-data",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-ff-archive",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-temp-redshift",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-reporting-files",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-internals",
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]

    resources = [
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-data/*",
      "arn:aws:s3:::axiom-${var.saas_customer}-${var.saas_env}-${var.aws_region}-data/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-ff-archive/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-temp-redshift/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-reporting-files/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-internals/*",
    ]
  }
}

resource "aws_iam_policy" "default_s3filefolder_policy" {
  name   = "default-s3filefolder-policy-${var.customer}-${var.env}"
  path   = "/"
  policy = var.service_type == "di" ? data.aws_iam_policy_document.default_s3filefolder_policy_doc_di.json : data.aws_iam_policy_document.default_s3filefolder_policy_doc_saas.json
}

resource "aws_iam_role_policy_attachment" "cv_default_s3filefolder_bucket_policy" {
  role       = aws_iam_role.cv_instance_profile.name
  policy_arn = aws_iam_policy.default_s3filefolder_policy.arn
}

resource "aws_iam_role_policy_attachment" "tomcat_default_s3filefolder_bucket_policy" {
  role       = aws_iam_role.tomcat.name
  policy_arn = aws_iam_policy.default_s3filefolder_policy.arn
}