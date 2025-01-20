# template variables substituted by init_tf.py
variable "vpn_connections" {
  type = "list"
  default = [
    {
      customer_bgp_asn = "",
      customer_internal_cidr_block = [],
      customer_vpn_gtw_ip = "",
      vpn_static_routes = "true",
      enable_vpn_acceleration = ""
    }
  ]
}

variable "customer_internal_cidr_list" {
  type = "list"
  default = []
}
