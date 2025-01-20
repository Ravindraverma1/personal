resource "aws_lb_target_group" "front_nlb_target_group" {
  count       = var.enable_vpn_access == "true" ? 1 : 0
  name        = "front-nlb-tg-${var.customer}-${var.env}"
  port        = 443
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    interval            = 10
    path                = ""
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = ""
  }

  stickiness {
    type    = "source_ip"
    enabled = false
  }
}

# 1st 4 and last IP of subnet reserved by AWS
locals {
  ip_list_1 = [for i in range(68, 95) : format("%s%d", "${var.internal_cidr_start1}.", i)]
  ip_list_2 = [for i in range(100, 127) : format("%s%d", "${var.internal_cidr_start1}.", i)]
}

resource "aws_lb_target_group_attachment" "front_nlb_target_ip_list_1" {
  count            = var.enable_vpn_access == "true" ? length(local.ip_list_1) : 0
  target_group_arn = aws_lb_target_group.front_nlb_target_group[0].arn
  target_id        = local.ip_list_1[count.index]
  port             = 443
}

resource "aws_lb_target_group_attachment" "front_nlb_target_ip_list_2" {
  count            = var.enable_vpn_access == "true" ? length(local.ip_list_2) : 0
  target_group_arn = aws_lb_target_group.front_nlb_target_group[0].arn
  target_id        = local.ip_list_2[count.index]
  port             = 443
}

# Citrix connection between VPCs requires traffic to be forwarded to internal NLB and then ALB (external/public)
resource "aws_lb_target_group" "citrixservices_nlb_target_group" {
  count       = var.enable_vpn_access == "false" && var.enable_citrixservices ? 1 : 0
  name        = "citrixser-nlb-tg-${var.customer}-${var.env}"
  port        = 443
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "alb"

  health_check {
    interval            = 10
    path                = "/cv/login/favicon.ico"
    protocol            = "HTTPS"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = ""
  }

  stickiness {
    type    = "source_ip"
    enabled = false
  }
}

resource "aws_lb_target_group_attachment" "citrixservices_nlb_target" {
  count            = var.enable_vpn_access == "false" && var.enable_citrixservices ? 1 : 0
  target_group_arn = aws_lb_target_group.citrixservices_nlb_target_group[0].arn
  target_id        = module.nginx_front_alb.this_lb_arn
  port             = 443
}