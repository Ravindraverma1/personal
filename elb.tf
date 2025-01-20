resource "aws_elb" "nginx_int_elb" {
  name            = "nginx-int-elb-${var.customer}-${var.env}"
  subnets         = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  security_groups = [aws_security_group.elb_internal_nginx.id]
  internal        = true

  #
  # This listener balances internal connections to tomcat API through NGINX internal site
  # that sits on NGINX servers on port 4443.
  #
  listener {
    instance_port     = 4443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  # Listener to handle Nginx Auth gateway redirection from port 443 to 4443
  listener {
    instance_port     = 4443
    instance_protocol = "tcp"
    lb_port           = 4443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:4443"
    interval            = 30
  }

  cross_zone_load_balancing   = false
  idle_timeout                = 3600
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name                 = "${var.aws_region}-${var.customer}-${var.env}-elb-internal-nginx"
    region               = var.business_region[var.aws_region]
    customer             = var.customer
    "${var.map_tag_key}" = "${var.map_tag_value}"
  }

  access_logs {
    bucket        = aws_s3_bucket.client_elb_access_logs_bucket.bucket
    bucket_prefix = "${var.env}-${var.aws_region}-logs/nginx_int_elb"
    interval      = 60
  }

  lifecycle {
    ignore_changes = [listener]
  }
}

