# VPN accessed Network Load Balancer with fixed private IP address
resource "aws_lb" "front_nlb_2az" {
  count              = var.enable_vpn_access == "true" ? 1 : 0
  name               = "front-nlb-${var.customer}-${var.env}"
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.front_b.id, aws_subnet.front_a.id]

  enable_deletion_protection = var.enable_del_protection #When VPN is turned on, change this nlb to "true" so that the environment VPN is protected from deletion
  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-front-nlb"
    region   = var.business_region[var.aws_region]
    customer = var.customer
    env      = var.env
  }
}

resource "aws_lb_listener" "front_end_2az" {
  count             = var.enable_vpn_access == "true" ? 1 : 0
  load_balancer_arn = aws_lb.front_nlb_2az[0].arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_nlb_target_group[0].arn
  }
}

# Citrix accessed Network Load Balancer with ALB as a target. Used as an alternative to VPN enabled connection option
resource "aws_lb" "citrixservices_nlb_2az" {
  count              = var.enable_vpn_access == "false" && var.enable_citrixservices ? 1 : 0
  name               = "citrixser-nlb-${var.customer}-${var.env}"
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.front_b.id, aws_subnet.front_a.id]

  enable_deletion_protection = "false"
  tags = {
    Name     = "${var.aws_region}-${var.customer}-${var.env}-citrixservices-nlb"
    region   = var.business_region[var.aws_region]
    customer = var.customer
    env      = var.env
  }
}

resource "aws_lb_listener" "citrixservices_end_2az" {
  count             = var.enable_vpn_access == "false" && var.enable_citrixservices ? 1 : 0
  load_balancer_arn = aws_lb.citrixservices_nlb_2az[0].arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.citrixservices_nlb_target_group[0].arn
  }
}
