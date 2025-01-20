data "aws_iam_policy_document" "s3_endpoint_policy_saas" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-01-client-repo",
      aws_s3_bucket.solution-deployment-bucket.arn,
      aws_s3_bucket.cv-default-key-bucket.arn,
      aws_s3_bucket.cv-default-data-bucket.arn,
      aws_s3_bucket.cv_archive_bucket.arn,
      aws_s3_bucket.client-bucket.arn,
      aws_s3_bucket.client_root_control_bucket.arn,
      aws_s3_bucket.env_temination_control_bucket.arn,
      aws_s3_bucket.application_logs_bucket.arn,
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-outbound-data",
      "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-s3-bucket-logging",
      "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-elb-access-logs",
      "arn:aws:s3:::amazonlinux.${var.aws_region}.amazonaws.com",
      "arn:aws:s3:::amazonlinux-2-repos-${var.aws_region}",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-ff-archive",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-temp-redshift",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-reporting-files",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-internals",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-data",
      "arn:aws:s3:::${var.namespace}-*-${var.name}-exe-${var.customer}-${var.env}-logs",
      "arn:aws:s3:::${var.namespace}-*-${var.name}-thrift-${var.customer}-${var.env}-logs",
    ]
  }
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-01-client-repo/*",
      "${aws_s3_bucket.solution-deployment-bucket.arn}/*",
      "${aws_s3_bucket.cv-default-key-bucket.arn}/*",
      "${aws_s3_bucket.cv-default-data-bucket.arn}/*",
      "${aws_s3_bucket.cv_archive_bucket.arn}/*",
      "${aws_s3_bucket.client-bucket.arn}/*",
      "${aws_s3_bucket.client_root_control_bucket.arn}/*",
      "${aws_s3_bucket.env_temination_control_bucket.arn}/*",
      "${aws_s3_bucket.application_logs_bucket.arn}/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-outbound-data/*",
      "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-s3-bucket-logging/*",
      "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-elb-access-logs/*",
      "arn:aws:s3:::packages.${var.aws_region}.*.amazonaws.com/*",
      "arn:aws:s3:::repo.${var.aws_region}.*.amazonaws.com/*",
      "arn:aws:s3:::amazonlinux.${var.aws_region}.amazonaws.com/*",
      "arn:aws:s3:::amazonlinux-2-repos-${var.aws_region}/*",
      "arn:aws:s3:::prod.${var.aws_region}.appinfo.src/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-ff-archive/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-temp-redshift/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-reporting-files/*",
      local.sf_bucket_arn,
      "arn:aws:s3:::${var.aws_region}.elasticmapreduce/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-internals/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-data/*",
      "arn:aws:s3:::${var.namespace}-*-${var.name}-exe-${var.customer}-${var.env}-logs/*",
      "arn:aws:s3:::${var.namespace}-*-${var.name}-thrift-${var.customer}-${var.env}-logs/*",
    ]
  }
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::prod-${var.aws_region}-starport-layer-bucket/*"
    ]
  }
}

data "aws_iam_policy_document" "s3_endpoint_policy_di" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-01-client-repo",
      aws_s3_bucket.solution-deployment-bucket.arn,
      aws_s3_bucket.cv-default-key-bucket.arn,
      aws_s3_bucket.cv-default-data-bucket.arn,
      aws_s3_bucket.cv_archive_bucket.arn,
      aws_s3_bucket.client-bucket.arn,
      aws_s3_bucket.client_root_control_bucket.arn,
      aws_s3_bucket.env_temination_control_bucket.arn,
      aws_s3_bucket.application_logs_bucket.arn,
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-outbound-data",
      "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-s3-bucket-logging",
      "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-elb-access-logs",
      "arn:aws:s3:::axiom-${var.saas_customer}-${var.saas_env}-${var.aws_region}-data",
      "arn:aws:s3:::axiom-${var.saas_customer}-${var.saas_env}-${var.aws_region}-key",
      "arn:aws:s3:::amazonlinux.${var.aws_region}.amazonaws.com",
      "arn:aws:s3:::amazonlinux-2-repos-${var.aws_region}",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-ff-archive",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-temp-redshift",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-reporting-files",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-internals",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-data",
      "arn:aws:s3:::${var.namespace}-*-${var.name}-exe-${var.customer}-${var.env}-logs",
      "arn:aws:s3:::${var.namespace}-*-${var.name}-thrift-${var.customer}-${var.env}-logs",
    ]
  }
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::axiom-${var.customer}-01-client-repo/*",
      "${aws_s3_bucket.solution-deployment-bucket.arn}/*",
      "${aws_s3_bucket.cv-default-key-bucket.arn}/*",
      "${aws_s3_bucket.cv-default-data-bucket.arn}/*",
      "${aws_s3_bucket.cv_archive_bucket.arn}/*",
      "${aws_s3_bucket.client-bucket.arn}/*",
      "${aws_s3_bucket.client_root_control_bucket.arn}/*",
      "${aws_s3_bucket.env_temination_control_bucket.arn}/*",
      "${aws_s3_bucket.application_logs_bucket.arn}/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-outbound-data/*",
      "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-s3-bucket-logging/*",
      "arn:aws:s3:::axiom-${data.aws_caller_identity.env_account.account_id}-${var.env}-${var.aws_region}-elb-access-logs/*",
      "arn:aws:s3:::packages.${var.aws_region}.*.amazonaws.com/*",
      "arn:aws:s3:::repo.${var.aws_region}.*.amazonaws.com/*",
      "arn:aws:s3:::amazonlinux.${var.aws_region}.amazonaws.com/*",
      "arn:aws:s3:::amazonlinux-2-repos-${var.aws_region}/*",
      "arn:aws:s3:::prod.${var.aws_region}.appinfo.src/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-worm-data/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-ff-archive/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-temp-redshift/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-pre-archival/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-reporting-files/*",
      "arn:aws:s3:::${var.aws_region}.elasticmapreduce/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-internals/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-staging/*",
      "arn:aws:s3:::axiom-${var.customer}-${var.env}-${var.aws_region}-emr-execution-data/*",
      "arn:aws:s3:::${var.namespace}-*-${var.name}-exe-${var.customer}-${var.env}-logs/*",
      "arn:aws:s3:::${var.namespace}-*-${var.name}-thrift-${var.customer}-${var.env}-logs/*",
    ]
  }
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:PutObject",
      "s3:PutObjectVersionTagging",
      "s3:PutObjectTagging",
    ]
    resources = [
      "arn:aws:s3:::axiom-${var.saas_customer}-${var.saas_env}-${var.aws_region}-data/*",
    ]
  }
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::axiom-${var.saas_customer}-${var.saas_env}-${var.aws_region}-key/*",
      "arn:aws:s3:::prod-${var.aws_region}-starport-layer-bucket/*",
    ]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.nat-route1b[0].id,
    aws_route_table.nat-route1a[0].id,
    aws_route_table.ig-route-table.id,
  ]
  policy = var.service_type == "di" ? data.aws_iam_policy_document.s3_endpoint_policy_di.json : data.aws_iam_policy_document.s3_endpoint_policy_saas.json
}

# KMS interface to CV subnets
# have to keep the name of true private_dns_enabled, for easier migration
resource "aws_vpc_endpoint" "kms_cv_subnets" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.app_b.id,
    aws_subnet.app_a.id,
  ]

  security_group_ids  = [aws_security_group.private_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "cv_ssm_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type = "Interface"

  # grant ssm endpoints to cv and solution deployment subnets
  subnet_ids = [aws_subnet.app_b.id, aws_subnet.app_a.id]

  security_group_ids  = [aws_security_group.private_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "lambda_sns_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.sns"
  vpc_endpoint_type = "Interface"

  subnet_ids = [aws_subnet.app_b.id, aws_subnet.app_a.id]

  security_group_ids  = [aws_security_group.private_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "lambda_events_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.events"
  vpc_endpoint_type = "Interface"

  subnet_ids = [aws_subnet.app_b.id, aws_subnet.app_a.id]

  security_group_ids  = [aws_security_group.private_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "lambda_sqs_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.sqs"
  vpc_endpoint_type = "Interface"

  subnet_ids = [aws_subnet.app_b.id, aws_subnet.app_a.id]

  security_group_ids  = [aws_security_group.private_endpoints.id]
  private_dns_enabled = true
}

### cloudWatch logs enpoints:
# have to keep the name of true private_dns_enabled, for easier migration
resource "aws_vpc_endpoint" "cloudwatch_logs_tomcat_subnets" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.app_b.id,
    aws_subnet.app_a.id,
  ]

  security_group_ids  = [aws_security_group.private_endpoints.id]
  private_dns_enabled = true
}

# have to keep the name of true private_dns_enabled, for easier migration
resource "aws_vpc_endpoint" "cloudwatch_monitor_tomcat_subnets" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.monitoring"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.app_b.id,
    aws_subnet.app_a.id,
  ]

  security_group_ids  = [aws_security_group.private_endpoints.id]
  private_dns_enabled = true
}

#Glue private endpoint
resource "aws_vpc_endpoint" "glue_endpoint" {
  count               = var.enable_redshift == "true" || var.enable_spark == "true" ? 1 : 0
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.glue"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.glue_subnets
  security_group_ids  = [aws_security_group.private_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "email_smtp_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.email-smtp"
  vpc_endpoint_type = "Interface"

  subnet_ids = data.aws_subnet_ids.ses_private_subnets.ids

  security_group_ids  = [aws_security_group.private_endpoints.id]
  private_dns_enabled = true
}

data "aws_vpc_endpoint_service" "ses" {
  service = "email-smtp"
}

data "aws_subnet_ids" "ses_private_subnets" {
  vpc_id = aws_vpc.main.id

  filter {
    name   = "subnet-id"
    values = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  }

  filter {
    name   = "availability-zone"
    values = data.aws_vpc_endpoint_service.ses.availability_zones
  }
}

#Snowflake private endpoint
resource "aws_vpc_endpoint" "snowflake" {
  count              = var.enable_snowflake == "true" ? 1 : 0
  vpc_id             = aws_vpc.main.id
  service_name       = var.sf_vpc_endpoint
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.app_a.id, aws_subnet.app_b.id]
  security_group_ids = [aws_security_group.snowflake[0].id]
}

locals {
  sf_stage_url     = [for x in var.sf_whitelist_privatelink : x.host if x.type == "STAGE"]
  sf_bucket_name   = length(local.sf_stage_url) == 0 ? "" : element(split(".", local.sf_stage_url[0]), 0)
  sf_bucket_arn    = length(local.sf_stage_url) == 0 ? "arn:aws:s3:::snowflake_bucket" : "arn:aws:s3:::${local.sf_bucket_name}/*"
  redshift_subnets = var.enable_redshift == "true" ? [aws_subnet.data_a.id, aws_subnet.data_b.id] : []
  spark_subnets    = var.enable_spark == "true" ? [aws_subnet.app_a.id, aws_subnet.app_b.id] : []
  glue_subnets     = var.enable_redshift == "true" && var.enable_spark == "true" ? flatten([local.redshift_subnets, local.spark_subnets]) : coalescelist(local.redshift_subnets, local.spark_subnets, [""])
}

resource "aws_vpc_endpoint" "tomcat_asg_endpoint" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.autoscaling"
  vpc_endpoint_type = "Interface"

  # grant ssm endpoints to cv and solution deployment subnets
  subnet_ids = [aws_subnet.app_b.id, aws_subnet.app_a.id]

  security_group_ids  = [aws_security_group.private_endpoints.id]
  private_dns_enabled = true
}


resource "aws_vpc_endpoint" "elasticmapreduce" {
  count               = var.enable_spark == "true" ? 1 : 0
  service_name        = "com.amazonaws.${var.aws_region}.elasticmapreduce"
  vpc_id              = aws_vpc.main.id
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  security_group_ids  = [aws_security_group.private_endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2" {
  count               = var.enable_spark == "true" ? 1 : 0
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_id              = aws_vpc.main.id
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  security_group_ids  = [aws_security_group.private_endpoints.id]
  private_dns_enabled = true
}

# WebProxy endpoint
data "aws_vpc_endpoint_service" "webproxy" {
  count = var.enable_webproxy == "true" ? 1 : 0
  provider = aws.sst
  filter {
    name   = "tag:Name"
    values = ["web-proxy-${var.jenkins_env_short}-${var.aws_region}"]
  }
}

resource "aws_vpc_endpoint" "webproxy" {
  count               = var.enable_webproxy == "true" ? 1 : 0
  vpc_id              = aws_vpc.main.id
  service_name        = data.aws_vpc_endpoint_service.webproxy[0].service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.app_a.id, aws_subnet.app_b.id]
  security_group_ids  = [aws_security_group.webproxy[0].id]
  private_dns_enabled = true
}
