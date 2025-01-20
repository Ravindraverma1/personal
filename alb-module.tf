module "nginx_front_alb" {
  source = "./modules/terraform-aws-alb-5.13.0"
  #source          = "terraform-aws-modules/alb/aws"
  #version         = "~> 5.0"
  name            = var.enable_vpn_access == "true" ? "nginx-int-alb-${var.customer}-${var.env}" : "nginx-front-alb-${var.customer}-${var.env}"
  vpc_id          = aws_vpc.main.id
  subnets         = [aws_subnet.front_gateway_b.id, aws_subnet.front_gateway_a.id]
  security_groups = [aws_security_group.elb_front_nginx.id]
  internal        = var.enable_vpn_access == "true" ? true : false #When VPN is turned on, change this elb to "internal" so that the environment DNS name returns a private IP address

  https_listeners = [
    {
      certificate_arn    = data.aws_acm_certificate.nginx-elb-certificate.arn
      port               = 443
      target_group_index = 0
    }
  ]

  extra_ssl_certs = var.enable_vpn_access == "false" && var.enable_citrixservices ? [
    {
      https_listener_index = 0
      certificate_arn    = data.aws_acm_certificate.citrixservices-nginx-elb-certificate[0].arn
    }
  ] : []

  #https_listeners_count       = "1"
  listener_ssl_policy_default = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  target_groups = [
    {
      name             = "nginx-front-alb-tg-${var.customer}-${var.env}"
      backend_protocol = "HTTPS"
      backend_port     = "443"
      target_type      = "instance"
      deregistration_delay = "60"
      health_check = {
        enabled  = true
        path     = "/cv/login/favicon.ico"
        protocol = "HTTPS"
      }
    }
  ]
  #target_groups_count = "1"

  #log_bucket_name     = aws_s3_bucket.client_elb_access_logs_bucket.bucket
  #log_location_prefix = "${var.env}-${var.aws_region}-logs/nginx_front_alb"
  access_logs = {
    name_prefix = "${var.env}-${var.aws_region}-logs/nginx_front_alb"
    bucket      = aws_s3_bucket.client_elb_access_logs_bucket.bucket
  }

  idle_timeout = 3600

  tags = {
    "Name"               = "${var.aws_region}-${var.customer}-${var.env}-alb-front-nginx"
    "region"             = var.business_region[var.aws_region]
    "customer"           = var.customer
    "env"                = var.env
  }
}

module "tc_int_alb" {
  source = "./modules/terraform-aws-alb-5.13.0"
  #source          = "terraform-aws-modules/alb/aws"
  #version         = "~> 5.0"
  name            = "tc-int-alb-${var.customer}-${var.env}"
  vpc_id          = aws_vpc.main.id
  subnets         = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  security_groups = [aws_security_group.elb_internal_tomcat.id]
  internal        = true

  https_listeners = [
    {
      certificate_arn    = data.aws_acm_certificate.tomcat-elb-internal-certificate.arn
      port               = 443
      target_group_index = 0
    }
  ]
  #https_listeners_count       = "1"
  listener_ssl_policy_default = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  target_groups = [
    {
      name             = "tc-int-alb-tg-${var.customer}-${var.env}"
      backend_protocol = "HTTPS"
      backend_port     = "8081"
      target_type      = "instance"
      deregistration_delay = "60"
      health_check = {
        enabled  = true
        path     = "/cv/ui/global/login/login/cv.ico"
        protocol = "HTTPS"
      }
    }
  ]
  #target_groups_count = "1"

  #log_bucket_name     = aws_s3_bucket.client_elb_access_logs_bucket.bucket
  access_logs = {
    name_prefix = "${var.env}-${var.aws_region}-logs/tc_int_alb"
    bucket      = aws_s3_bucket.client_elb_access_logs_bucket.bucket
  }
  #log_location_prefix = "${var.env}-${var.aws_region}-logs/tc_int_alb"

  idle_timeout = 3600

  tags = {
    "Name"               = "${var.aws_region}-${var.customer}-${var.env}-alb-internal-tomcat"
    "region"             = var.business_region[var.aws_region]
    "customer"           = var.customer
    "env"                = var.env
  }
}
