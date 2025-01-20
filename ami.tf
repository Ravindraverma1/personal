data "aws_ami" "ec2-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

data "aws_ami" "nginx_packer" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["packer-axiom-nginx-${var.release}"]
  }
}

data "aws_ami" "cv_packer" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["packer-axiom-cv-${var.release}"]
  }
}

data "aws_ami" "tomcat_packer" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["packer-axiom-tomcat-${var.release}"]
  }
}

data "aws_ami" "bastion" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["packer-axiom-bastion-${var.release}"]
  }
}

