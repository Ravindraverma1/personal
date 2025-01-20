// share ...with the second account.
resource "aws_ram_principal_association" "tgw_principal_assoc" {
  count    = (var.enable_vpn_access == "true" || var.enable_vpn_access == "prep") && var.use_transit_gateway == "true" && var.env_account_id != var.vpnowner_account_id ? 1 : 0
  provider = aws.vpnowner
  principal = element(
    data.aws_caller_identity.env_account.*.account_id,
    count.index,
  )
  resource_share_arn = data.aws_ssm_parameter.tgw_resource_share_arn[0].value
}
/*
#The resources are not supported as of IAC 1.38
resource "aws_ram_principal_association" "citrixservices_tgw_principal_assoc" {
  count    = var.enable_citrixservices == "true" ? 1 : 0
  provider = aws.citrixservices
  principal = element(
    data.aws_caller_identity.env_account.*.account_id,
    count.index,
  )
  resource_share_arn = data.aws_ssm_parameter.citrixservices_tgw_resource_share_arn[0].value
}
*/