
output "fortanix_user_access_key_id" {
  depends_on = [data.aws_ssm_parameter.fortanix_secret_access_key]
  value      = var.enable_byok == "true" ? join("",data.aws_ssm_parameter.fortanix_access_key_id.*.value) : ""
}

output "fortanix_user_secret_access_key" {
  depends_on = [data.aws_ssm_parameter.fortanix_secret_access_key]
  value      = var.enable_byok == "true" ? join("",data.aws_ssm_parameter.fortanix_secret_access_key.*.value) : ""
}