locals {
  tc_aws_security_groups = [aws_security_group.ssh_from_bastion.id, aws_security_group.tomcat.id]
  tc_security_groups     = var.enable_oci_db == "true" ? concat(local.tc_aws_security_groups, [aws_security_group.oci_resources[0].id]) : local.tc_aws_security_groups
}

module "autoscale_group_tomcat" {
  source  = "cloudposse/ec2-autoscale-group/aws"
  version = "0.8.0" #for terraform0.12

  namespace   = ""
  stage       = ""
  environment = ""
  name        = "tomcat-asg-${var.customer}-${var.env}"

  image_id      = data.aws_ami.tomcat_packer.id
  instance_type = var.instance_type_tomcat

  # All inputs to `block_device_mappings` have to be defined
  block_device_mappings = [
    {
      device_name  = "/dev/sdh"
      no_device    = "false"
      virtual_name = "null"
      ebs = {
        encrypted             = true
        volume_size           = var.tomcat_vol_size
        delete_on_termination = true
        iops                  = null
        kms_key_id            = null
        snapshot_id           = aws_ebs_snapshot.tomcat_ebs_snapshot.id
        volume_type           = "gp3"
      }
    },
    {
      device_name  = "/dev/sdf"
      no_device    = "false"
      virtual_name = "null"
      ebs = {
        encrypted             = true
        volume_size           = var.tomcat_log_vol_size
        delete_on_termination = true
        iops                  = null
        kms_key_id            = null
        snapshot_id           = null
        volume_type           = "gp3"
      }
    }
  ]

  # use spot instance on dev & staging
  instance_market_options = var.jenkins_env == "production" ? null : {
    market_type  = "spot"
    spot_options = null
  }

  iam_instance_profile_name = aws_iam_instance_profile.tomcat.name
  security_group_ids        = local.tc_security_groups
  subnet_ids                = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  health_check_type         = "EC2"
  min_size                  = 1
  max_size                  = 1
  #desired_capacity            = 1
  wait_for_capacity_timeout   = "20m"
  health_check_grace_period   = 30
  associate_public_ip_address = false
  user_data_base64            = base64encode(data.template_file.userdata_tomcat.rendered)
  termination_policies        = ["OldestInstance"]

  tags = {
    Name                 = "${var.aws_region}-${var.customer}-${var.env}-tomcat"
    region               = var.business_region[var.aws_region]
    customer             = var.customer
    env                  = var.env
    instancerole         = "tomcat"
    "${var.map_tag_key}" = "${var.map_tag_value}"
  }

  # Auto-scaling policies and CloudWatch metric alarms
  autoscaling_policies_enabled = false
  #default_alarms_enabled       = false

  target_group_arns = [module.tc_int_alb.target_group_arns[0]]
}

resource "aws_autoscaling_lifecycle_hook" "tomcat_asg_terminate" {
  name                   = "tomcat_asg_terminate"
  autoscaling_group_name = module.autoscale_group_tomcat.autoscaling_group_name #"tomcat-asg-${var.customer}-${var.env}"
  default_result         = "CONTINUE"
  heartbeat_timeout      = 60
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
  depends_on             = [module.autoscale_group_tomcat]
}

resource "aws_autoscaling_attachment" "tomcat-elb-attach" {
  autoscaling_group_name = module.autoscale_group_tomcat.autoscaling_group_id #aws_autoscaling_group.tomcat-asg.id
  alb_target_group_arn   = module.tc_int_alb.target_group_arns[0]
}

resource "aws_autoscaling_lifecycle_hook" "tomcat_asg_launching" {
  name                   = "tomcat_asg_launching"
  autoscaling_group_name = module.autoscale_group_tomcat.autoscaling_group_name #aws_autoscaling_group.tomcat-asg.name
  default_result         = "CONTINUE"
  heartbeat_timeout      = 120
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
}

data "aws_instances" "tomcat" {
  instance_tags = {
    Name = "${var.aws_region}-${var.customer}-${var.env}-tomcat"
  }

  instance_state_names = ["running", "pending"]
  depends_on           = [module.autoscale_group_tomcat]
}

resource "aws_lb_target_group_attachment" "tomcat_tg_attach" {
  target_group_arn = module.tc_int_alb.target_group_arns[0]
  target_id        = data.aws_instances.tomcat.ids[0]
}
