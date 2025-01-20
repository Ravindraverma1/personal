resource "aws_guardduty_detector" "guardduty_detector" {
  enable                       = var.enable_aws_config == "true" ? true : false
  finding_publishing_frequency = "SIX_HOURS"
}

