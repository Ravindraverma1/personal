# Templates for the cloud-init's cloud-config:
data "template_file" "userdata_bastion" {
  template = file("templates/userdata_bastion.tpl")

  vars = {
    environment              = var.env
    hostname                 = "bastion"
    region                   = var.aws_region
    customer                 = var.customer
    enable_migration_peering = var.enable_migration_peering
  }
}

data "template_file" "userdata_nginx" {
  template = file("templates/userdata_nginx.tpl")

  vars = {
    environment              = var.env
    hostname                 = "nginx"
    region                   = var.aws_region
    dd_id                    = var.dd_id
    dd_app                   = var.dd_app
    dd_proxy_host            = var.dd_proxy_host
    dd_proxy_port            = var.dd_proxy_port
    enable_dd                = var.enable_dd
    customer                 = var.customer
    logstash_host            = var.logstash_host
    cv_version               = var.cv_version
    customer_timezone        = var.customer_timezone
    switch_saml              = var.switch_saml
    logz_enable              = var.logz_enable
    customer_adfs_identifier = var.customer_adfs_identifier
    enable_migration_peering = var.enable_migration_peering
    enable_rest              = var.enable_rest
    log_retention_period     = var.log_retention_period
    cv_ui_retention_period   = var.cv_ui_retention_period
    logzio_proxy_host        = var.logzio_proxy_host
    logs_logzio_token        = var.logs_logzio_token
    logs_logzio_port         = var.logs_logzio_port
  }
}

data "template_file" "userdata_app" {
  template = file("templates/userdata_cv.tpl")

  vars = {
    mount_address = format(
      "%s.efs.%s.amazonaws.com",
      aws_efs_file_system.efs_cv.id,
      var.aws_region,
    )
    environment               = var.env
    customer                  = var.customer
    release                   = var.release
    hostname                  = "cv"
    db_host                   = var.enable_aurora == "true" ? module.aurora.aurora_instance_endpoint : module.db.database_endpoint
    region                    = var.aws_region
    dd_id                     = var.dd_id
    enable_dd                 = var.enable_dd
    dd_proxy_host             = var.dd_proxy_host
    dd_proxy_port             = var.dd_proxy_port
    cv_version                = var.cv_version
    region                    = var.aws_region
    db_username               = var.db_username
    db_name                   = var.db_name[var.db_parameter_group_family]
    db_engine                 = var.db_engine
    db_engine_version         = var.db_engine_version
    db_port                   = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
    db_parameter_group_family = var.db_parameter_group_family
    cv_system_schema          = var.cv_system_schema[var.db_parameter_group_family]
    cv_user_schema            = var.cv_user_schema[var.db_parameter_group_family]
    cv_db_engine              = var.cv_db_engine_map[var.db_parameter_group_family]
    axcloud_domain            = var.axcloud_domain
    disable_os_command        = var.disable_os_command
    service_type              = var.service_type
    saas_customer             = var.saas_customer
    saas_env                  = var.saas_env
    logstash_host             = var.logstash_host
    cv_xmx                    = var.instance_type_cv_xmx
    db_local_admin_pwd = var.db_local_admin_user != "" && var.db_local_admin_user != " " ? var.db_local_admin_user : chomp(
      element(
        concat(data.aws_ssm_parameter.db_local_admin_user.*.value, [""]),
        0,
      ),
    )
    db_ro_user_pwd = var.db_axiom_ro_user != "" && var.db_axiom_ro_user != " " ? var.db_axiom_ro_user : chomp(
      element(
        concat(data.aws_ssm_parameter.db_axiom_ro_user.*.value, [""]),
        0,
      ),
    )
    db_meta_ro_user_pwd = var.db_axiom_meta_ro_user != "" && var.db_axiom_meta_ro_user != " " ? var.db_axiom_meta_ro_user : chomp(
      element(
        concat(data.aws_ssm_parameter.db_axiom_meta_ro_user.*.value, [""]),
        0,
      ),
    )
    db_user_pwd              = chomp(data.aws_ssm_parameter.database_password.value)
    db_ssl_enabled           = local.db_ssl_enabled[var.db_parameter_group_family]
    db_ssl_port              = var.db_ssl_port[var.db_parameter_group_family]
    ssl_keystore_pwd         = chomp(data.aws_ssm_parameter.db_ssl_keystore_pwd.value)
    r_package_install_list   = chomp(var.r_package_install_list)
    customer_adfs_identifier = var.customer_adfs_identifier
    customer_directory_name  = var.customer_directory_name
    switch_saml              = var.switch_saml
    logz_enable              = var.logz_enable
    customer_timezone        = var.customer_timezone
    cv_log_level             = var.cv_log_level
    enable_outbound_transfer = var.enable_outbound_transfer
    start_cv                 = var.start_cv
    enable_worm_compliance   = var.enable_worm_compliance
    recreate_cv_schema       = var.recreate_cv_schema
    enable_data_lineage      = var.enable_data_lineage
    reset_meta_usrs_paswd    = var.reset_meta_usrs_paswd
    blacklisted_cv_tag       = trimspace(var.blacklisted_cv_tag)
    override_classes         = var.override_classes
    override_services        = var.override_services
    whitelist_classes        = trimspace(var.whitelist_classes)
    whitelist_services       = trimspace(var.whitelist_services)
    aurora_enabled           = var.enable_aurora
    aurora_db_engine         = var.aurora_db_engine
    enable_migration_peering = var.enable_migration_peering
    cv_wlog_retention_period = var.cv_wlog_retention_period
    log_retention_period     = var.log_retention_period
    cv_ui_retention_period   = var.cv_ui_retention_period
    enable_oci_db            = var.enable_oci_db
    is_sysdb_postgres_oci    = var.is_sysdb_postgres_oci
    oci_mtu_size             = var.oci_mtu_size
    is_sysdb_postgres_oci    = var.is_sysdb_postgres_oci
    enable_snowflake         = var.enable_snowflake
    enable_spark             = var.enable_spark
    logzio_proxy_host        = var.logzio_proxy_host
    logs_logzio_token        = var.logs_logzio_token
    logs_logzio_port         = var.logs_logzio_port
  }
  depends_on = [
    null_resource.db_local_admin_user,
    null_resource.db_axiom_ro_user,
    null_resource.db_axiom_meta_ro_user,
    null_resource.generate-rds-password,
    null_resource.db_ssl_keystore_config,
    data.aws_ssm_parameter.db_local_admin_user,
    data.aws_ssm_parameter.db_axiom_ro_user,
    data.aws_ssm_parameter.db_axiom_meta_ro_user,
    data.aws_ssm_parameter.database_password,
    data.aws_ssm_parameter.db_ssl_keystore_pwd,
  ]
}

data "template_cloudinit_config" "userdata_app" {
  part {
    content_type = "text/cloud-config"
    content      = data.template_file.userdata_app.rendered
  }
}

data "template_file" "userdata_tomcat" {
  template = file("templates/userdata_tomcat.tpl")

  vars = {
    mount_address = format(
      "%s.efs.%s.amazonaws.com",
      aws_efs_file_system.efs_cv.id,
      var.aws_region,
    )
    environment               = var.env
    hostname                  = "tomcat"
    region                    = var.aws_region
    cv_version                = var.cv_version
    dd_id                     = var.dd_id
    enable_dd                 = var.enable_dd
    dd_proxy_host             = var.dd_proxy_host
    dd_proxy_port             = var.dd_proxy_port
    customer                  = var.customer
    release                   = var.release
    logstash_host             = var.logstash_host
    tomcat_xmx                = var.instance_type_tomcat_xmx
    db_engine                 = var.db_engine
    db_engine_version         = var.db_engine_version
    db_port                   = local.db_ssl_enabled[var.db_parameter_group_family] == "true" ? var.db_ssl_port[var.db_parameter_group_family] : var.db_port[var.db_parameter_group_family]
    db_name                   = var.db_name[var.db_parameter_group_family]
    db_ssl_enabled            = local.db_ssl_enabled[var.db_parameter_group_family]
    db_ssl_port               = var.db_ssl_port[var.db_parameter_group_family]
    db_parameter_group_family = var.db_parameter_group_family
    ssl_keystore_pwd          = chomp(data.aws_ssm_parameter.db_ssl_keystore_pwd.value)
    customer_timezone         = var.customer_timezone
    enable_data_lineage       = var.enable_data_lineage
    aurora_enabled            = var.enable_aurora
    aurora_db_engine          = var.aurora_db_engine
    enable_migration_peering  = var.enable_migration_peering
    logz_enable               = var.logz_enable
    enable_oci_db             = var.enable_oci_db
    is_sysdb_postgres_oci     = var.is_sysdb_postgres_oci
    oci_mtu_size              = var.oci_mtu_size
    is_sysdb_postgres_oci     = var.is_sysdb_postgres_oci
    log_retention_period      = var.log_retention_period
    cv_ui_retention_period    = var.cv_ui_retention_period
    logzio_proxy_host         = var.logzio_proxy_host
    logs_logzio_token         = var.logs_logzio_token
    logs_logzio_port          = var.logs_logzio_port
  }
  depends_on = [
    null_resource.db_ssl_keystore_config,
    data.aws_ssm_parameter.db_ssl_keystore_pwd,
  ]
}

