# spot instance if environment is not production
resource "aws_spot_instance_request" "bastion" { # due to limitation of terraform and aws spot instance cannot have tags now
  wait_for_fulfillment = true
  count                = var.jenkins_env != "production" && var.ssh_access == "true" ? 1 : 0
  spot_price           = var.spot_price
  ami                  = data.aws_ami.bastion.id
  instance_type        = var.instance_type_bastion
  user_data            = data.template_file.userdata_bastion.rendered
  iam_instance_profile = aws_iam_instance_profile.generic.name

  network_interface {
    network_interface_id = aws_network_interface.bastion[0].id
    device_index         = 0
  }

  provisioner "local-exec" {
    command = "aws --profile ${var.customer}-${var.env} ec2 create-tags --resources ${aws_spot_instance_request.bastion[0].spot_instance_id} --tags Key=Name,Value=${var.aws_region}-${var.customer}-${var.env}-bastion Key=region,Value=${var.business_region[var.aws_region]} Key=customer,Value=${var.customer} Key=instancerole,Value=bastion"
  }
}

# normal instance if environment is production
resource "aws_instance" "bastion" {
  count                = var.jenkins_env == "production" && var.ssh_access == "true" ? 1 : 0
  ami                  = data.aws_ami.bastion.id
  instance_type        = var.instance_type_bastion
  user_data            = data.template_file.userdata_bastion.rendered
  iam_instance_profile = aws_iam_instance_profile.generic.name

  network_interface {
    network_interface_id = aws_network_interface.bastion[0].id
    device_index         = 0
  }

  tags = {
    Name         = "${var.aws_region}-${var.customer}-${var.env}-bastion"
    region       = var.business_region[var.aws_region]
    customer     = var.customer
    instancerole = "bastion"
  }
}

