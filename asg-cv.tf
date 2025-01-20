locals {
  cv_aws_security_groups = [aws_security_group.ssh_from_bastion.id, aws_security_group.cv.id]
  cv_security_groups     = var.enable_oci_db == "true" ? concat(local.cv_aws_security_groups, [aws_security_group.oci_resources[0].id]) : local.cv_aws_security_groups
}

resource "null_resource" "aur_instance_status_change" {
  provisioner "local-exec" {
    #when    = create
    command = "scripts/wait-db-instance-status.sh ${var.env_aws_profile} ${module.aurora.aurora_instance_endpoint} available 1800"
  }
}

resource "null_resource" "db_status_change" {
  provisioner "local-exec" {
    #when    = create
    command = "scripts/wait-db-instance-status.sh ${var.env_aws_profile} ${module.db.database_id} available 1800"
  }
}

module "autoscale_group_cv" {
  source  = "cloudposse/ec2-autoscale-group/aws"
  version = "0.8.0" #for terraform0.12

  namespace   = ""
  stage       = ""
  environment = ""
  name        = "cv-asg-${var.customer}-${var.env}"

  image_id      = data.aws_ami.cv_packer.id
  instance_type = var.instance_type_cv

  # All inputs to `block_device_mappings` have to be defined
  block_device_mappings = [
    {
      device_name  = "/dev/sda1"
      no_device    = "false"
      virtual_name = "root"
      ebs = {
        encrypted             = true
        volume_size           = var.cv_root_vol_size
        delete_on_termination = true
        iops                  = null
        kms_key_id            = null
        snapshot_id           = null
        volume_type           = "gp3"
      }
    },
    {
      device_name  = "/dev/sdh"
      no_device    = "false"
      virtual_name = "null"
      ebs = {
        encrypted             = true
        volume_size           = var.cv_vol_size
        delete_on_termination = true
        iops                  = null
        kms_key_id            = null
        snapshot_id           = null
        volume_type           = "gp3"
      }
    },
    {
      device_name  = "/dev/sdf"
      no_device    = "false"
      virtual_name = "null"
      ebs = {
        encrypted             = true
        volume_size           = var.cv_log_vol_size
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

  iam_instance_profile_name = aws_iam_instance_profile.cv.name
  security_group_ids        = local.cv_security_groups
  subnet_ids                = [aws_subnet.app_b.id, aws_subnet.app_a.id]
  health_check_type         = "EC2"
  min_size                  = 1
  max_size                  = 1
  #desired_capacity            = 1
  wait_for_capacity_timeout   = "20m"
  health_check_grace_period   = 30
  associate_public_ip_address = false
  user_data_base64            = base64encode(data.template_file.userdata_app.rendered)
  termination_policies        = ["OldestInstance"]

  tags = {
    Name                 = "${var.aws_region}-${var.customer}-${var.env}-cv"
    region               = var.business_region[var.aws_region]
    customer             = var.customer
    env                  = var.env
    instancerole         = "cv"
    "${var.map_tag_key}" = "${var.map_tag_value}"
  }

  # Auto-scaling policies and CloudWatch metric alarms
  autoscaling_policies_enabled = false
  #default_alarms_enabled       = false
}

resource "aws_autoscaling_lifecycle_hook" "cv_asg_terminate" {
  name                   = "cv_asg_terminate"
  autoscaling_group_name = module.autoscale_group_cv.autoscaling_group_name # "cv-asg-${var.customer}-${var.env}"
  default_result         = "CONTINUE"
  heartbeat_timeout      = 60
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
  depends_on             = [module.autoscale_group_cv] #[aws_autoscaling_group.cv-asg]
}

# resource "aws_autoscaling_attachment" "cv-elb-attach" {
#   autoscaling_group_name = "${aws_autoscaling_group.cv-asg.id}"
#   elb                    = "${aws_elb.cv_int_elb.id}"
# }

resource "aws_autoscaling_lifecycle_hook" "cv_asg_launching" {
  name                   = "cv_asg_launching"
  autoscaling_group_name = module.autoscale_group_cv.autoscaling_group_name #aws_autoscaling_group.cv-asg.name
  default_result         = "CONTINUE"
  heartbeat_timeout      = 120
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
}

