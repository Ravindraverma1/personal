module "deploy_solution_module" {
  source                   = "./modules/deploy-solution"
  customer                 = var.customer
  env                      = var.env
  axcloud_domain           = var.axcloud_domain
  cv_version               = var.cv_version
  aws_region               = var.aws_region
  db_name                  = var.db_name[var.db_parameter_group_family]
  db_port                  = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
  db_engine                = var.db_engine
  cv_user_schema           = var.cv_user_schema[var.db_parameter_group_family]
  lambda_subnet_ids        = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  lambda_security_group_id = aws_security_group.lambda_security_group.id
}

module "cv_process_queue" {
  #source = "./modules/terraform-aws-sqs-1.2.1"
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 3.1.0"
  create  = "true"
  name    = "cv_process_queue-${var.customer}-${var.env}"

  #sqs_queue_with_kms = 1
  kms_master_key_id = aws_kms_key.sqs.arn

  tags = {
    "Name"     = "${var.aws_region}-${var.customer}-${var.env}-cv_process_queue"
    "region"   = var.business_region[var.aws_region]
    "customer" = var.customer
  }
}

resource "aws_cloudwatch_event_rule" "get_backgroundprocess_rule" {
  name        = "get_backgroundprocess-${var.customer}-${var.env}"
  description = "Gets CV backgroundprocess state"

  # custom event pattern to be sent to lambda function
  event_pattern = <<PATTERN
{
  "source": [
    "com.axiom.solution-${var.customer}-${var.env}"
  ]
}
PATTERN

}

resource "aws_cloudwatch_event_target" "get_backgroundprocess_target" {
  rule      = aws_cloudwatch_event_rule.get_backgroundprocess_rule.name
  target_id = "get_backgroundprocess_${var.customer}-${var.env}"
  arn       = module.get_background_process_info_module.lambda_function_arn
}

resource "aws_kms_key" "sqs" {
  description         = "SQS Customer Master Key for ${var.customer}-${var.env}"
  enable_key_rotation = true

  tags = {
    Name        = "sqs-${var.customer}-${var.env}-${var.aws_region}"
    Region      = var.business_region[var.aws_region]
    Customer    = var.customer
    Environment = var.env
  }
}

resource "aws_kms_alias" "sqs_alias" {
  name          = "alias/sqs-${var.customer}-${var.env}"
  target_key_id = aws_kms_key.sqs.key_id
}

resource "aws_s3_bucket" "solution-deployment-bucket" {
  bucket = "${var.deployment_solution_s3_bucket_prefix}-${var.customer}-${var.env}"
  acl    = "private"

  tags = {
    Name        = "${var.deployment_solution_s3_bucket_prefix}-${var.customer}-${var.env}"
    Environment = var.env
    Customer    = var.customer
  }
  versioning {
    enabled = true
  }

  logging {
    target_bucket = aws_s3_bucket.s3_bucket_logging.id
    target_prefix = "${var.env}-${var.aws_region}-logs/${var.deployment_solution_s3_bucket_prefix}-${var.customer}-${var.env}/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
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
      "Resource": "arn:aws:s3:::${var.deployment_solution_s3_bucket_prefix}-${var.customer}-${var.env}/*",
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

resource "aws_s3_bucket_public_access_block" "public_block_sol_dep" {
  bucket                  = aws_s3_bucket.solution-deployment-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

