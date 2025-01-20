module "aws_backup" {
  source = "./modules/terraform-aws-backup-0.3.1"

  # Environment profile
  env_aws_profile = var.env_aws_profile

  # Vault
  vault_name        = "vault-${var.env_aws_profile}"
  vault_kms_key_arn = aws_kms_key.backup.arn

  # Plan
  plan_name = "efs-plan-${var.env_aws_profile}"

  # One rule
  rule_name              = "rule-efs"
  rule_schedule          = var.efs_backup_schedule
  rule_start_window      = var.efs_backup_start_window
  rule_completion_window = var.efs_backup_completion_window

  #rule_lifecycle_cold_storage_after = ""
  rule_lifecycle_delete_after = var.efs_backup_lifecycle_delete_after

  # One selection
  selection_name      = "selection-efs"
  selection_resources = [aws_efs_file_system.efs_cv.arn]

  # Tags
  tags = {
    customer    = var.customer
    Environment = var.env
    region      = var.business_region[var.aws_region]
  }
}
