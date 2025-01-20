data "template_file" "kms_policy_tpl_np" {
  template = file("templates/kms_policy_nonprod.json.tpl")

  vars = {
    accountid = data.aws_caller_identity.env_account.account_id
  }
}

data "template_file" "kms_policy_tpl" {
  template = file("templates/kms_policy_prod.json.tpl")

  vars = {
    accountid = data.aws_caller_identity.env_account.account_id
  }
}

resource "aws_kms_key" "ebs" {
  description         = "EBS Customer Master Key for ${var.customer}-${var.env}"
  enable_key_rotation = true
  policy              = var.jenkins_env != "production" ? data.template_file.kms_policy_tpl_np.rendered : data.template_file.kms_policy_tpl.rendered

  tags = {
    Name        = "ebs-${var.customer}-${var.env}-${var.aws_region}"
    region      = var.business_region[var.aws_region]
    customer    = var.customer
    Environment = var.env
  }
}

resource "aws_kms_alias" "ebs-alias" {
  name          = "alias/ebs-${var.customer}-${var.env}"
  target_key_id = aws_kms_key.ebs.key_id
}

data "aws_ebs_volume" "tomcat_ebs" {
  most_recent = true

  filter {
    name = "tag:Name"

    #values = ["axiom-tomcat-volume-${var.customer}-${var.env}"]
    values = [var.release == "0" ? "axiom-tomcat-volume-${var.customer}-${var.env}" : "axiom-tomcat-volume-${var.release}*"]
  }
}

resource "aws_ebs_snapshot" "tomcat_ebs_snapshot" {
  volume_id = data.aws_ebs_volume.tomcat_ebs.id

  tags = {
    #Name = "axiom-tomcat-volume-snap-${var.customer}-${var.env}"
    Name = var.release == "0" ? "axiom-tomcat-snap-${var.customer}-${var.env}" : "axiom-tomcat-snap-${var.release}"
  }
}
