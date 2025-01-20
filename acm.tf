###
# nginx elb external (front)
###
resource "null_resource" "nginx-elb-acm" {
  provisioner "local-exec" {
    command = "python3 scripts/acm-get-cert.py --domain ${var.customer}-${var.env}.${var.axcloud_domain} --zoneid ${var.dns_zone_id} --profile ${var.env_aws_profile} --region ${var.aws_region} --assume --role-arn ${var.cross_account_route53_role_arn}"
  }
}

data "aws_acm_certificate" "nginx-elb-certificate" {
  domain     = "${var.customer}-${var.env}.${var.axcloud_domain}"
  statuses   = ["ISSUED"]
  depends_on = [null_resource.nginx-elb-acm]
}

###
# internal tomcat (tc-internal)
###
resource "null_resource" "tomcat-elb-internal-acm" {
  provisioner "local-exec" {
    command = "python3 scripts/acm-get-cert.py --domain tc-internal.${var.customer}-${var.env}.${var.axcloud_domain} --zoneid ${var.dns_zone_id} --profile ${var.env_aws_profile} --region ${var.aws_region} --assume --role-arn ${var.cross_account_route53_role_arn}"
  }
}

data "aws_acm_certificate" "tomcat-elb-internal-certificate" {
  domain     = "tc-internal.${var.customer}-${var.env}.${var.axcloud_domain}"
  statuses   = ["ISSUED"]
  depends_on = [null_resource.tomcat-elb-internal-acm]
}

###
# nginx elb external (front) for Citrix users
###
resource "null_resource" "citrixservices-nginx-elb-acm" {
  count     = var.enable_vpn_access == "false" && var.enable_citrixservices ? 1 : 0
  provisioner "local-exec" {
    command = "python3 scripts/acm-get-cert.py --domain citrixservices-${var.customer}-${var.env}.${var.axcloud_domain} --zoneid ${var.dns_zone_id} --profile ${var.env_aws_profile} --region ${var.aws_region} --assume --role-arn ${var.cross_account_route53_role_arn}"
  }
}

resource "null_resource" "citrixservices-nginx-elb-acm-del" {
  count     = var.enable_vpn_access == "false" && var.enable_citrixservices == "false" ? 1 : 0
  provisioner "local-exec" {
    command = "python3 scripts/acm-del-cert.py --domain citrixservices-${var.customer}-${var.env}.${var.axcloud_domain} --profile ${var.env_aws_profile} --region ${var.aws_region}"
  }
}

data "aws_acm_certificate" "citrixservices-nginx-elb-certificate" {
  count      = var.enable_vpn_access == "false" && var.enable_citrixservices ? 1 : 0
  domain     = "citrixservices-${var.customer}-${var.env}.${var.axcloud_domain}"
  statuses   = ["ISSUED"]
  depends_on = [null_resource.citrixservices-nginx-elb-acm[0]]
}