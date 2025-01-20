module "db" {
  source                      = "./modules/db"
  customer                    = var.customer
  env                         = var.env
  allocated_storage           = var.db_allocated_storage
  max_allocated_storage       = var.db_max_allocated_storage
  identifier                  = var.db_id
  engine                      = var.db_engine
  engine_version              = var.db_engine_version
  storage_type                = var.db_storage_type
  instance_class              = var.db_instance_class
  db_name                     = var.db_name[var.db_parameter_group_family]
  license_model               = var.db_license_model[var.db_parameter_group_family]
  db_username                 = var.db_username
  password                    = data.aws_ssm_parameter.database_password.value
  db_subnet_group_name        = var.use_2az == "0" ? element(concat(aws_db_subnet_group.default.*.id, [""]), 0) : element(concat(aws_db_subnet_group.default_2az.*.id, [""]), 0)
  vpc_security_group_ids      = [aws_security_group.rds-sg.id]
  skip_final_snapshot         = var.db_skip_final_snapshot
  storage_encrypted           = var.db_storage_encrypted
  kms_key_id                  = var.enable_byok == "true" ? data.aws_kms_alias.rds_fortanix_key[0].target_key_arn : aws_kms_key.rds[0].arn
  copy_tags_to_snapshot       = var.db_copy_tags_to_snapshot
  backup_retention_period     = var.db_backup_retention_period
  apply_immediately           = var.db_apply_immediately
  allow_major_version_upgrade = var.db_allow_major_version_upgrade
  auto_minor_version_upgrade  = var.db_auto_minor_version_upgrade
  maintenance_window          = var.db_maintenance_window
  backup_window               = var.db_backup_window
  port                        = var.db_port[var.db_parameter_group_family]
  snapshot_schedule           = var.db_snapshot_schedule
  zone_id                     = aws_route53_zone.internal.zone_id
  db_snapshot_id              = trimspace(var.db_snapshot_id)
  db_parameter_group_family   = var.db_parameter_group_family
  db_enhance_monitor_interval = var.db_enhance_monitor_interval
  db_enhance_monitor_role_arn = data.aws_iam_role.created_rds_enhance_mon_role[0].arn
  db_multi_az                 = var.db_multi_az
  db_publicly_accessible      = var.db_publicly_accessible

  #tag related variables here
  tag_name   = "${var.aws_region}-${var.customer}-${var.env}-db-${var.db_engine}"
  tag_region = var.business_region[var.aws_region]
  aws_region = var.aws_region

  # end of tag related variables

  ##VPC and N/W related variables
  #subnet_ids = [var.use_2az == "0" ? element(concat(aws_db_subnet_group.default.*.subnet_ids, [""]), 0) : element(concat(aws_db_subnet_group.default_2az.*.subnet_ids, [""]), 0)]
  vpc_id                  = aws_vpc.main.id
  ingress_security_groups = [aws_security_group.tomcat.id, aws_security_group.cv.id]
  db_params_apply_mode    = var.db_params_apply_mode

  # RDS Snapshot Retention Policy
  db_enable_snapshot_cleanup     = var.db_enable_snapshot_cleanup
  db_snapshot_retention_weekdays = var.db_snapshot_retention_weekdays
  db_snapshot_retention_weeks    = var.db_snapshot_retention_weeks
  db_snapshot_retention_months   = var.db_snapshot_retention_months
  db_snapshot_retention_years    = var.db_snapshot_retention_years
  db_snapshot_cleanup_schedule   = var.db_snapshot_cleanup_schedule
  disable_oracle_ssl             = var.disable_oracle_ssl
  enable_aurora                  = var.enable_aurora
}

