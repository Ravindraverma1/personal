module "transit-gateway-vpn" {
  source                       = "../modules/transit-gateway-vpn"
  providers                    = {
    aws.vpnowner = "aws.vpnowner"
    awsvpn = "awsvpn"
  }
  aws_asn_side                 = "${var.aws_asn_side}"
  aws_region                   = "${var.aws_region}"
  env_aws_profile              = "${var.env_aws_profile}"
  customer                     = "${var.customer}"
  env                          = "${var.env}"
  create_tgw_vpn               = "${var.create_tgw_vpn}"
  vpn_connections              = "${var.vpn_connections}"
  vpn_ecmp_support             = "${var.vpn_ecmp_support}"
}
