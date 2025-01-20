module "aurora" {
  source = "./modules/aurora"

  #cluster related params
  customer = var.customer
  env      = var.env

  #global_cluster_identifier   = "${var.customer}-${var.env}-${var.global_cluster_identifier_suffix}"
  cluster_identifier = "${var.aurora_id_prefix}-${var.customer}-${var.env}"
  source_region      = var.aws_region

  #engine                      = "${var.db_engine}"
  aurora_db_engine          = var.aurora_db_engine
  aurora_db_engine_version  = var.aurora_db_engine_version
  engine_mode               = var.engine_mode
  engine_version            = var.db_engine_version
  kms_key_id                = var.enable_byok == "true" ? data.aws_kms_alias.rds_fortanix_key[0].target_key_arn : aws_kms_key.rds[0].arn
  database_name             = var.db_name[var.db_parameter_group_family]
  master_username           = var.db_username
  master_password           = data.aws_ssm_parameter.database_password.value
  skip_final_snapshot       = var.db_skip_final_snapshot
  backup_retention_period   = var.db_backup_retention_period
  backup_window             = var.db_backup_window
  maintenance_window        = var.db_maintenance_window
  port                      = var.db_port[var.db_parameter_group_family]
  db_subnet_group_name      = var.use_2az == "0" ? element(concat(aws_db_subnet_group.default.*.id, [""]), 0) : element(concat(aws_db_subnet_group.default_2az.*.id, [""]), 0)
  vpc_security_group_ids    = [aws_security_group.rds-sg.id]
  storage_encrypted         = var.db_storage_encrypted
  apply_immediately         = var.db_apply_immediately
  db_parameter_group_family = var.db_parameter_group_family
  zone_id                   = aws_route53_zone.internal.zone_id

  #db_cluster_parameter_group_name = "${var.db_parameter_group_family}"
  copy_tags_to_snapshot = var.db_copy_tags_to_snapshot

  #iam_roles                   = ["${data.aws_iam_role.created_rds_enhance_mon_role.arn}"]
  #enabled_cloudwatch_logs_exports = "${var.enabled_cloudwatch_logs_exports}"

  #cluster instance related params
  replica_scale_enabled  = var.replica_scale_enabled
  replica_scale_min      = var.replica_scale_min
  replica_count          = var.replica_count
  instance_class         = var.db_instance_class
  db_publicly_accessible = var.db_publicly_accessible

  #db_parameter_group_name     = "${var.db_parameter_group_family}"
  #monitoring_role_arn         = ["${data.aws_iam_role.created_rds_enhance_mon_role.arn}"]
  monitoring_role_arn          = data.aws_iam_role.created_rds_enhance_mon_role[0].arn
  db_enhance_monitor_interval  = var.db_enhance_monitor_interval
  auto_minor_version_upgrade   = var.db_auto_minor_version_upgrade
  performance_insights_enabled = var.performance_insights_enabled

  #ca_cert_identifier          = "${var.ca_cert_identifier}"
  db_snapshot_id = trimspace(var.db_snapshot_id)

  #instance_type               = "${var.db_instance_class}"
  aurora_db_instance_class = var.aurora_db_instance_class

  #already defined in cluster params
  #db_subnet_group_name        = "${var.use_2az == "0" ? element(concat(aws_db_subnet_group.default.*.id, list("")), 0) : element(concat(aws_db_subnet_group.default_2az.*.id, list("")), 0)}"
  #maintenance_window          = "${var.db_maintenance_window}"
  #apply_immediately           = "${var.db_apply_immediately}"

  #identifier                  = "${var.db_id}"
  #storage_type                = "${var.db_storage_type}"
  #allow_major_version_upgrade = "${var.db_allow_major_version_upgrade}"
  #snapshot_schedule           = "${var.db_snapshot_schedule}"
  #zone_id                     = "${aws_route53_zone.internal.zone_id}"
  #using the replica variable instead of this one
  #db_multi_az                 = "${var.db_multi_az}"

  #tag related variables here
  tag_name   = "${var.aws_region}-${var.customer}-${var.env}-aur-${var.db_engine}"
  tag_region = var.business_region[var.aws_region]

  # end of tag related variables

  ##VPC and N/W related variables
  #subnet_ids                  = ["${var.use_2az == "0" ? element(concat(aws_db_subnet_group.default.*.subnet_ids, list("")), 0) : element(concat(aws_db_subnet_group.default_2az.*.subnet_ids, list("")), 0)}"]
  #vpc_id                      = "${aws_vpc.main.id}"
  #ingress_security_groups     = ["${aws_security_group.tomcat.id}", "${aws_security_group.cv.id}"]
  #db_params_apply_mode        = "${var.db_params_apply_mode}"

  #added via variables.tf - check these
  #disable_oracle_ssl             = "${var.disable_oracle_ssl}"
  #allocated_storage = ""
  #aws_region = ""
  #db_name = ""
  #db_password = ""
  #db_username = ""
  #max_allocated_storage = ""

  ###for resources.tf
  snapshot_schedule              = var.db_snapshot_schedule
  db_enable_snapshot_cleanup     = var.db_enable_snapshot_cleanup
  db_snapshot_retention_weekdays = var.db_snapshot_retention_weekdays
  db_snapshot_retention_weeks    = var.db_snapshot_retention_weeks
  db_snapshot_retention_months   = var.db_snapshot_retention_months
  db_snapshot_retention_years    = var.db_snapshot_retention_years
  db_snapshot_cleanup_schedule   = var.db_snapshot_cleanup_schedule
  aws_region                     = var.aws_region
  enable_aurora                  = var.enable_aurora
  aurora_id_prefix               = var.aurora_id_prefix
}

