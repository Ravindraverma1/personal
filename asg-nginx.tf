module "autoscale_group_nginx" {
  source  = "cloudposse/ec2-autoscale-group/aws"
  version = "0.8.0" #for terraform0.12

  namespace   = ""
  stage       = ""
  environment = ""
  name        = "nginx-asg-${var.customer}-${var.env}"

  image_id      = data.aws_ami.nginx_packer.id
  instance_type = var.instance_type_nginx

  # use spot instance on dev & staging
  instance_market_options = var.jenkins_env == "production" ? null : {
    market_type  = "spot"
    spot_options = null
  }

  iam_instance_profile_name = aws_iam_instance_profile.generic.name
  security_group_ids        = [aws_security_group.ssh_from_bastion.id, aws_security_group.nginx.id]
  subnet_ids                = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  health_check_type         = "EC2"
  min_size                  = 1
  max_size                  = 1
  #desired_capacity            = 1
  wait_for_capacity_timeout   = "20m"
  health_check_grace_period   = 30
  associate_public_ip_address = false
  user_data_base64            = base64encode(data.template_file.userdata_nginx.rendered)
  termination_policies        = ["OldestInstance"]

  tags = {
    Name                 = "${var.aws_region}-${var.customer}-${var.env}-nginx"
    region               = var.business_region[var.aws_region]
    customer             = var.customer
    env                  = var.env
    instancerole         = "nginx"
    "${var.map_tag_key}" = "${var.map_tag_value}"
  }

  # Auto-scaling policies and CloudWatch metric alarms
  autoscaling_policies_enabled = false
  #default_alarms_enabled       = false

  target_group_arns = [module.nginx_front_alb.target_group_arns[0]]
  load_balancers    = [aws_elb.nginx_int_elb.id]
}


resource "aws_autoscaling_attachment" "nginx-elb-attach" {
  autoscaling_group_name = module.autoscale_group_nginx.autoscaling_group_id #aws_autoscaling_group.nginx-asg.id
  alb_target_group_arn   = module.nginx_front_alb.target_group_arns[0]
}

resource "aws_autoscaling_attachment" "nginx-internal-elb-attach" {
  autoscaling_group_name = module.autoscale_group_nginx.autoscaling_group_id #aws_autoscaling_group.nginx-asg.id
  elb                    = aws_elb.nginx_int_elb.id
}

resource "aws_autoscaling_lifecycle_hook" "nginx_asg_launching" {
  name                   = "nginx_asg_launching"
  autoscaling_group_name = module.autoscale_group_nginx.autoscaling_group_name #aws_autoscaling_group.nginx-asg.name
  default_result         = "CONTINUE"
  heartbeat_timeout      = 120
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
}

data "aws_instances" "nginx" {
  instance_tags = {
    Name = "${var.aws_region}-${var.customer}-${var.env}-nginx"
  }

  instance_state_names = ["running", "pending"]
  depends_on           = [module.autoscale_group_nginx]
}

resource "aws_lb_target_group_attachment" "nginx_tg_attach" {
  target_group_arn = module.nginx_front_alb.target_group_arns[0]
  target_id        = data.aws_instances.nginx.ids[0]
}
