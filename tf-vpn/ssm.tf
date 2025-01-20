# SSM parameter of tgw share resource reference
resource "aws_ssm_parameter" "tgw_resource_share_arn_param" {
  name        = "/${var.customer}/tgw_resource_share_arn"
  description = "Transit gateway resource share ARN"
  type        = "String"
  value       = "${module.transit-gateway-vpn.tgw_resource_share_arn}"
  overwrite   = true
}

# SSM parameter of VPN attachments
resource "aws_ssm_parameter" "vpn_attachment_ids_param" {
  //count       = "${length(module.transit-gateway-vpn.vpn_attachment_ids)}"
  name        = "/${var.customer}/vpn_attachment_ids"
  description = "VPN attachment IDs"
  type        = "StringList"
  value       = "${join(",", module.transit-gateway-vpn.vpn_attachment_ids)}"
  overwrite   = true
}
