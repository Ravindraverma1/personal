########################################################################
# Public DNS
########################################################################
# zone ${var.axcloud_domain}

resource "aws_route53_record" "bastion" {
  count    = var.ssh_access == "true" ? 1 : 0
  provider = aws.sst
  zone_id  = var.dns_zone_id
  name     = "bastion-${var.customer}-${var.env}"
  type     = "A"
  ttl      = "6"
  records  = [aws_eip.bastion[0].public_ip]
}

resource "aws_route53_record" "tc-internal" {
  provider = aws.sst
  zone_id  = var.dns_zone_id
  name     = "tc-internal.${var.customer}-${var.env}"
  type     = "A"

  alias {
    name                   = module.tc_int_alb.this_lb_dns_name
    zone_id                = module.tc_int_alb.this_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "nginx-internal" {
  provider = aws.sst
  zone_id  = var.dns_zone_id
  name     = "nginx-internal.${var.customer}-${var.env}"
  type     = "A"

  alias {
    name                   = aws_elb.nginx_int_elb.dns_name
    zone_id                = aws_elb.nginx_int_elb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "front_2az" {
  count    = var.use_2az == "1" ? 1 : 0
  provider = aws.sst
  zone_id  = var.dns_zone_id
  name     = "${var.customer}-${var.env}"
  type     = "A"

  alias {
    name                   = var.enable_vpn_access == "true" ? element(concat(aws_lb.front_nlb_2az.*.dns_name, [""]), 0) : module.nginx_front_alb.this_lb_dns_name
    zone_id                = var.enable_vpn_access == "true" ? element(concat(aws_lb.front_nlb_2az.*.zone_id, [""]), 0) : module.nginx_front_alb.this_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "front" {
  count    = var.use_2az == "0" ? 1 : 0
  provider = aws.sst
  zone_id  = var.dns_zone_id
  name     = "${var.customer}-${var.env}"
  type     = "A"

  alias {
    name                   = var.enable_vpn_access == "true" ? element(concat(aws_lb.front_nlb_2az.*.dns_name, [""]), 0) : module.nginx_front_alb.this_lb_dns_name
    zone_id                = var.enable_vpn_access == "true" ? element(concat(aws_lb.front_nlb_2az.*.zone_id, [""]), 0) : module.nginx_front_alb.this_lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "citrixservices_2az" {
  count    = var.enable_vpn_access == "false" && var.enable_citrixservices ? 1 : 0
  provider = aws.sst
  zone_id  = var.dns_zone_id
  name     = "citrixservices-${var.customer}-${var.env}"
  type     = "A"

  alias {
    name                   = element(concat(aws_lb.citrixservices_nlb_2az.*.dns_name, [""]), 0)
    zone_id                = element(concat(aws_lb.citrixservices_nlb_2az.*.zone_id, [""]), 0)
    evaluate_target_health = true
  }
}
#####################################################################
# Internal DNS
#####################################################################

resource "aws_route53_zone" "internal" {
  name = "${var.customer}-${var.env}.axiom"
  vpc {
    vpc_id = aws_vpc.main.id
  }

  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_route53_zone_association" "migration" {
  count   = var.enable_migration_peering == "true" ? 1 : 0
  zone_id = aws_route53_zone.internal.zone_id
  vpc_id  = data.aws_vpc_peering_connection.migration_peering[0].vpc_id
}

resource "aws_route53_record" "bastion-internal" {
  count   = var.ssh_access == "true" ? 1 : 0
  zone_id = aws_route53_zone.internal.zone_id
  name    = "bastion"
  type    = "CNAME"
  ttl     = "6"
  records = [aws_eip.bastion[0].private_ip]
}

# create a dummy Route53 record for CV instance, actual IP will be updated by cv_dns_update Lambda function
resource "aws_route53_record" "cv-instance" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "cv-elb-internal"
  type    = "A"
  ttl     = "6"
  records = ["127.0.0.1"]

  lifecycle {
    ignore_changes = [records]
  }
}

# create a dummy Route53 record for NGINX instance, actual IP will be updated by the dns_update Lambda function
resource "aws_route53_record" "nginx-instance" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "nginx"
  type    = "A"
  ttl     = "6"
  records = ["127.0.0.2"]

  lifecycle {
    ignore_changes = [records]
  }
}

# create a dummy Route53 record for TOMCAT instance, actual IP will be updated by the dns_update Lambda function
resource "aws_route53_record" "tc-instance" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "tomcat"
  type    = "A"
  ttl     = "6"
  records = ["127.0.0.3"]

  lifecycle {
    ignore_changes = [records]
  }
}

resource "aws_route53_record" "tc-internal-alb" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "tc-elb-internal"
  type    = "A"

  alias {
    name                   = module.tc_int_alb.this_lb_dns_name
    zone_id                = module.tc_int_alb.this_lb_zone_id
    evaluate_target_health = true
  }
}

#####################################################################
# Snowflake DNS
#####################################################################
resource "aws_route53_zone" "snowflake" {
  count   = var.enable_snowflake == "true" ? 1 : 0
  name = "privatelink.snowflakecomputing.com"
  vpc {
    vpc_id = aws_vpc.main.id
  }

  lifecycle {
    ignore_changes = [vpc]
  }

  tags = {
    Name = "Hosted zone for ${var.customer}-${var.env} Snowflake PrivateLink"
    customer = var.customer
    env      = var.env
  }
}

locals {
  sf_account_url = [for x in var.sf_whitelist_privatelink:x.host if x.type == "SNOWFLAKE_DEPLOYMENT"]
  sf_ocsp_url = [for x in var.sf_whitelist_privatelink:x.host if x.type == "OCSP_CACHE"]
}

resource "aws_route53_record" "snowflake_privatelink_account_url" {
  count   = var.enable_snowflake == "true" ? 1 : 0
  zone_id = aws_route53_zone.snowflake[0].zone_id
  name    = local.sf_account_url[0]
  type    = "CNAME"
  ttl     = "6"
  records = ["${lookup(aws_vpc_endpoint.snowflake[0].dns_entry[0], "dns_name")}"]
}

resource "aws_route53_record" "snowflake_privatelink_ocsp_url" {
  count   = var.enable_snowflake == "true" ? 1 : 0
  zone_id = aws_route53_zone.snowflake[0].zone_id
  name    = local.sf_ocsp_url[0]
  type    = "CNAME"
  ttl     = "6"
  records = ["${lookup(aws_vpc_endpoint.snowflake[0].dns_entry[0], "dns_name")}"]
}

/*
resource "aws_route53_record" "kms" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "kms.${aws_route53_zone.internal.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${lookup(aws_vpc_endpoint.kms.dns_entry[0], "dns_name")}"]
}

resource "aws_route53_record" "kms1" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "kms.${aws_route53_zone.internal.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${lookup(aws_vpc_endpoint.kms1.dns_entry[0], "dns_name")}"]
}

resource "aws_route53_record" "kms2" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name    = "kms.${aws_route53_zone.internal.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${lookup(aws_vpc_endpoint.kms2.dns_entry[0], "dns_name")}"]
}
*/
