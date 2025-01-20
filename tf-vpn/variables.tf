variable aws_region {default=""}
variable env_aws_profile {default=""}
variable customer {default=""}
variable "env" {
  default = ""
}
# whether to create tgw vpn
variable "create_tgw_vpn" {
  default = "false"
}
# AWS ASN
variable "aws_asn_side" {
  default = "64512"
}
# VPNowner AWS profile
variable "vpnowner_aws_profile" {
  default = ""
}

variable "vpn_ecmp_support" {
  default = "enable"
}