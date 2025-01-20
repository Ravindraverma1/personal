output "bastion_dns_name" {
  value = var.ssh_access == "true" ? [aws_route53_record.bastion[0].fqdn] : []
}

output "aws_ssm_parameter_db_local_admin_password" {
  value = data.aws_ssm_parameter.db_local_admin_user.*.value
}

output "aws_ssm_parameter_db_local_admin_password_refresh" {
  value = var.db_local_admin_user
}

output "aws_ssm_parameter_db_password" {
  value = data.aws_ssm_parameter.database_password.value
}

output "aws_ssm_parameter_axiom_ro_user_password" {
  value = data.aws_ssm_parameter.db_axiom_ro_user.*.value
}

output "aws_ssm_parameter_axiom_axiom_meta_user_password" {
  value = var.ssh_access == "true" && var.output_sensitive_password == "true" ? data.aws_ssm_parameter.db_axiom_meta_user.*.value : []
}

output "aws_ssm_parameter_axiom_axiom_meta_ro_user_password" {
  value = data.aws_ssm_parameter.db_axiom_meta_ro_user.*.value
}

output "s3uploader_access_key_id" {
  value = aws_iam_access_key.s3uploader.id
}

output "s3uploader_secret_access_key" {
  value = aws_iam_access_key.s3uploader.secret
}

output "outbound_transfer_access_key_id" {
  value = join("", aws_iam_access_key.outbound-transfer.*.id)
}

output "outbound_transfer_secret_access_key" {
  value = join("", aws_iam_access_key.outbound-transfer.*.secret)
}

output "outbound_transfer_kms_master_key_id" {
  value = var.enable_byok == "false" ? join("", aws_kms_key.outbound-transfer.*.id) : join("", data.aws_kms_alias.outbound-transfer_fortanix_key.*.target_key_id)
}

#output "outbound_transfer_kms_master_key_id_byok" {
#  value = var.enable_byok == "true" ? join("", data.aws_kms_alias.outbound-transfer_fortanix_key.*.target_key_id) : ""
#}

# output "workspaces_ad_admin_password" {
#    value=  data.aws_ssm_parameter.workspace_ad_admin_password.*.value
# }

output "citrixservices_url" {
  value = var.enable_vpn_access == "false" && var.enable_citrixservices ? "citrixservices-${var.customer}-${var.env}.${var.axcloud_domain}" : ""
}

output "sftp_transfer_secret_access_key" {
  value = join("", aws_iam_access_key.sftptransfer.*.secret)
}

output "sftp_transfer_access_key_id" {
  value = join("", aws_iam_access_key.sftptransfer.*.id)
}

output "ssm_db_password" {
  value = local.ssm_db_password
}

output "ssm_wallet_password" {
  value = local.ssm_wallet_password
}

output "fortanix_user_access_key_id" {
  value = var.enable_byok == "true" ? join("", data.aws_ssm_parameter.fortanix_access_key_id.*.value) : ""
}

output "fortanix_user_secret_access_key" {
  value = var.enable_byok == "true" ? join("", data.aws_ssm_parameter.fortanix_secret_access_key.*.value) : ""
}

output "monitoring_access_key_id" {
  value = aws_iam_access_key.monitoring.id
}

output "monitoring_secret_access_key" {
  value = aws_iam_access_key.monitoring.secret
}
