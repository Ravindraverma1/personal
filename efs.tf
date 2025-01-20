resource "aws_kms_key" "efs" {
  description         = "EFS Customer Master Key for ${var.customer}-${var.env}"
  enable_key_rotation = true

  tags = {
    Name        = "efs-${var.customer}-${var.env}-${var.aws_region}"
    region      = var.business_region[var.aws_region]
    customer    = var.customer
    Environment = var.env
  }
}

resource "aws_kms_alias" "efs-alias" {
  name          = "alias/efs-${var.customer}-${var.env}"
  target_key_id = aws_kms_key.efs.key_id
}

resource "aws_efs_file_system" "efs_cv" {
  creation_token                  = "cv_server-${var.customer}-${var.env}"
  encrypted                       = true
  kms_key_id                      = aws_kms_key.efs.arn
  throughput_mode                 = var.efs_throughput_mode
  provisioned_throughput_in_mibps = var.efs_provisioned_throughput

  tags = {
    Name         = "${var.aws_region}-${var.customer}-${var.env}-efs-cv"
    region       = var.business_region[var.aws_region]
    customer     = var.customer
    env          = var.env
    instancerole = "efs_volume_cv"
  }
}

resource "aws_efs_mount_target" "efs_mount_first" {
  file_system_id  = aws_efs_file_system.efs_cv.id
  subnet_id       = aws_subnet.data_a.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "efs_mount_second" {
  file_system_id  = aws_efs_file_system.efs_cv.id
  subnet_id       = aws_subnet.data_b.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "efs_mount_third" {
  file_system_id  = aws_efs_file_system.efs_cv.id
  subnet_id       = aws_subnet.data_c[0].id
  security_groups = [aws_security_group.efs.id]
  count           = var.use_2az == "0" ? 1 : 0
}

