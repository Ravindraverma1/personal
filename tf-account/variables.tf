variable "aws_region" {
  default = ""
}

variable "env_aws_profile" {
  default = ""
}

variable "customer" {
  default = ""
}

variable "ses_aws_region" {
  default = "eu-west-1"
}

# for creating AWS Config rules
variable "enable_aws_config" {
  default = "true"
}

# SES Domain definition
variable "axcloud_domain" {
  default = ""
}

variable "account_alerts_domains" {
  type    = list(string)
  default = []
}

variable "cis_notification_email" {
  default = "operations@axcloud.io"
}

#CT related variables
variable "cloudtrail_trail_name" {
  default = "axiomsl-audit-ct"
}

variable "cloudtrail_enable_logging" {
  default = "true"
}

variable "cloudtrail_enable_log_file_validation" {
  default = "true"
}

variable "cloudtrail_is_multi_region_trail" {
  default = "true"
}

variable "cloudtrail_include_global_service_events" {
  default = "true"
}

variable "cloudtrail_s3_bucket" {
  default = "axiomsl-cloudtrail"
}

variable "cloudtrail_kms_arn_audit_account" {
  default = ""
}

variable "sst_account_id" {
  default = ""
}

variable "master_account_id" {
  default = ""
}

variable "dd_account_id" {
  default = ""
}

