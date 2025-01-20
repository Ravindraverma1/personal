######################Variables for DB module##########################
variable "customer" {
  default = ""
}

variable "env" {
  default = ""
}

variable "db_allocated_storage" {
  default = 10
}

variable "db_max_allocated_storage" {
  default = 1000
}

variable "db_id" {
  default = ""
}

variable "db_engine" {
  default = ""
}

variable "db_engine_version" {
  default = ""
}

variable "db_storage_type" {
  default = "gp2"
}

variable "db_instance_class" {
  default = ""
}

variable "db_license_model" {
  type = map(string)
  default = {
    "postgres12"      = "postgresql-license"
    "postgres11"      = "postgresql-license"
    "postgres10"      = "postgresql-license"
    "postgres9.6"     = "postgresql-license"
    "oracle-se2-12.1" = "bring-your-own-license"
    "oracle-ee-12.1"  = "bring-your-own-license" #this is hadrdcoded for now,as RDS supports Oracle EE with BYOL
    "oracle-ee-19"    = "bring-your-own-license"
    "oracle-se2-19"   = "bring-your-own-license"
    "others"          = "bring-your-own-license"
  }
}

variable "db_name" {
  type = map(string)
  default = {
    "postgres12"        = "axiom_db"
    "postgres11"        = "axiom_db"
    "postgres10"        = "axiom_db"
    "postgres9.6"       = "axiom_db"
    "oracle-se2-12.1"   = "AXIOMDB" #needs to be in caps and without an underscore (for Oracle DBs), else TF detects as a diff and destroys existing DB
    "oracle-ee-12.1"    = "AXIOMDB" #needs to be in caps and without an underscore (for Oracle DBs), else TF detects as a diff and destroys existing DB
    "oracle-ee-19"      = "AXIOMDB" #needs to be in caps and without an underscore (for Oracle DBs), else TF detects as a diff and destroys existing DB
    "oracle-se2-19"     = "AXIOMDB" #needs to be in caps and without an underscore (for Oracle DBs), else TF detects as a diff and destroys existing DB
    "aurora-postgresql" = "axiom_db"
    "others"            = "axiomdb"
  }
}

variable "user_data_app" {
  default = ""
}

variable "db_port" {
  type = map(string)
  default = {
    "postgres12"        = "5432"
    "postgres11"        = "5432"
    "postgres10"        = "5432"
    "postgres9.6"       = "5432"
    "oracle-se2-12.1"   = "1521"
    "oracle-ee-12.1"    = "1521"
    "oracle-ee-19"      = "1521"
    "oracle-se2-19"     = "1521"
    "aurora-postgresql" = "5432"
    "others"            = "5432" #this needs to be handled for future db setup
  }
}

variable "cv_db_engine_map" {
  type = map(string)
  default = {
    "postgres12"        = "postgres"
    "postgres11"        = "postgres"
    "postgres10"        = "postgres"
    "postgres9.6"       = "postgres"
    "oracle-se2-12.1"   = "oracle"
    "oracle-ee-12.1"    = "oracle"
    "oracle-ee-19"      = "oracle"
    "oracle-se2-19"     = "oracle"
    "aurora-postgresql" = "postgres"
    "others"            = "postgres"
  }
}

variable "cv_system_schema" {
  type = map(string)
  default = {
    "postgres12"        = "meta"
    "postgres11"        = "meta"
    "postgres10"        = "meta"
    "postgres9.6"       = "meta"
    "oracle-se2-12.1"   = "axiom_meta_user"
    "oracle-ee-12.1"    = "axiom_meta_user"
    "oracle-ee-19"      = "axiom_meta_user"
    "oracle-se2-19"     = "axiom_meta_user"
    "aurora-postgresql" = "meta"
    "others"            = "meta"
  }
}

variable "cv_user_schema" {
  type = map(string)
  default = {
    "postgres12"        = "udata"
    "postgres11"        = "udata"
    "postgres10"        = "udata"
    "postgres9.6"       = "udata"
    "oracle-se2-12.1"   = "axiom_user"
    "oracle-ee-12.1"    = "axiom_user"
    "oracle-ee-19"      = "axiom_user"
    "oracle-se2-19"     = "axiom_user"
    "aurora-postgresql" = "udata"
    "others"            = "udata"
  }
}

variable "disable_oracle_ssl" {
  default = "false"
}

locals {
  db_ssl_enabled = {
    "postgres12"        = "false"
    "postgres11"        = "false"
    "postgres10"        = "false" #this needs to be set once CV10 supports E2E postgres SSL communication (10.0.21 onwards)
    "postgres9.6"       = "false" #this needs to be set once CV10 supports E2E postgres SSL communication (10.0.21 onwards)
    "oracle-se2-12.1"   = var.disable_oracle_ssl ? "false" : "true"
    "oracle-ee-12.1"    = var.disable_oracle_ssl ? "false" : "true"
    "oracle-ee-19"      = var.disable_oracle_ssl ? "false" : "true"
    "oracle-se2-19"     = var.disable_oracle_ssl ? "false" : "true"
    "aurora-postgresql" = "false"
    "others"            = "false" #let this be false always (untill all RDS'es are covered)
  }
}

variable "db_ssl_port" {
  type = map(string)
  default = {
    "postgres12"        = "5432"
    "postgres11"        = "5432"
    "postgres10"        = "5432" #this needs to be set once CV10 supports E2E postgres SSL communication (10.0.21 onwards)
    "postgres9.6"       = "5432" #this needs to be set once CV10 supports E2E postgres SSL communication (10.0.21 onwards)
    "oracle-se2-12.1"   = "2484"
    "oracle-ee-12.1"    = "2484"
    "oracle-ee-19"      = "2484"
    "oracle-se2-19"     = "2484"
    "aurora-postgresql" = "5432"
    "others"            = "5432" #defaulted to postgres, this needs to be handled in the future
  }
}

variable "partitioning_enabled" {
  type = map(string)
  default = {
    "postgres12"        = "true"
    "postgres11"        = "true"
    "postgres10"        = "false"
    "postgres9.6"       = "false"
    "oracle-se2-12.1"   = "false"
    "oracle-ee-12.1"    = "false"
    "oracle-se2-19"     = "false"
    "oracle-ee-19"      = "false"
    "aurora-postgresql" = "false"
    "others"            = "false" #let this be false always (untill all RDS'es are covered)
  }
}

variable "db_server_dn" { #future used when distinguisked name can be used with DBSource (with SSL)
  default = ""
}

variable "db_multi_az" {
  default = false
}

variable "db_username" {
  default = "axiom_user"
}

variable "db_skip_final_snapshot" {
  default = false
}

variable "db_storage_encrypted" {
  default = true
}

variable "db_copy_tags_to_snapshot" {
  default = true
}

variable "db_backup_retention_period" {
  type        = string
  description = "Number of days for which RDS backups are retained"
  default     = 2
}

variable "db_apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  default     = false
}

variable "db_allow_major_version_upgrade" {
  default = false
}

variable "db_auto_minor_version_upgrade" {
  default = false
}

variable "db_maintenance_window" {
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi' UTC "
  default     = "Mon:03:00-Mon:04:00"
}

variable "db_backup_window" {
  description = "When AWS can run snapshot, can't overlap with maintenance window"
  default     = "22:00-03:00"
}

# Backups
variable "db_snapshot_schedule" {
  description = "Cron expression scheduling RDS backups"
  default     = "cron(15 */2 * * ? *)"
}

variable "db_snapshot_id" {
  default = ""
}

variable "enable_dd" {
  default = "true"
}

variable "db_params_apply_mode" {
  description = "(Optional) [immediate] (default), or [pending-reboot]. Some engines can't apply some parameters without a reboot, and you will need to specify [pending-reboot] here."
  default     = "pending-reboot"
}

#rds_apply_params_mode
variable "db_publicly_accessible" {
  description = "Determines if database can be publicly available (NOT recommended)"
  default     = false
}

variable "db_parameter_group_family" {
  default = ""
}

variable "db_enhance_monitor_interval" {
  default = "60"
}

# RDS retention Policy
variable "db_enable_snapshot_cleanup" {
  default = "false"
}

variable "db_snapshot_retention_weekdays" {
  default = "MON,THU"
}

variable "db_snapshot_retention_weeks" {
  default = "4"
}

variable "db_snapshot_retention_months" {
  default = "6"
}

variable "db_snapshot_retention_years" {
  default = "2"
}

variable "db_snapshot_cleanup_schedule" {
  description = "Cron expression scheduling RDS cleanup - Default : Saturday at 01:00 AM GMT"
  default     = "cron(00 01 * * ? 6)"
}

#######################################################################

#################Non-module variables below###########################

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_dns_hostnames" {
  default = true
}

variable "enable_dns_support" {
  default = true
}

variable "subnet_id" {
  default = ""
}

variable "dns_zone_id" {
  default = "Z36S89JQT1EOZ0"
}

variable "aws_region" {
  default = ""
}

variable "elk_region" {
  default = ""
}

variable "upload_key_name" {
  default = "saras_deployer2"
}

variable "release" {
  default = "0"
}

variable "dd_id" {
  default     = ""
  description = "DataDog integration ID"
}

variable "dd_app" {
  default     = ""
  description = "DataDog integration application ID"
}

variable "ha_proxy_vpc" {
  description = "VPC for HA-proxy on SST account"
  default     = "vpc-0f245c20044696664"
}

variable "ha_proxy_subnet" {
  description = "Subnet where HA-proxy resides (SST account)"
  default     = "172.16.0.0/16"
}

variable "ha_proxy_region" {
  description = "Region where HA-proxy resides (SST account)"
  default     = "eu-west-1"
}

variable "dd_proxy_host" {
  default     = "app.datadoghq.com"
  description = "DataDog integration application ha-proxy host"
}

variable "dd_proxy_port" {
  default     = "443"
  description = "DataDog integration application ha-proxy port"
}

variable "cv_version" {
  description = "ControllerView package release version"
  default     = ""
}

variable "nginx_version" {
  description = "Nginx package mainline release version"
  default     = ""
}

variable "internal_cidr_start1" {
  default     = ""
  description = "First three segments of the internal IP range"
}

variable "internal_cidr_start2" {
  default     = ""
  description = "First three segments of the internal IP range"
}

variable "disable_os_command" {
  default = "true"
}

# Instance types
variable "instance_type_tomcat" {
  default     = ""
  description = "Instance size of tomcat server. Set in tfvars file by terraform init script."
}

variable "instance_type_cv" {
  default     = ""
  description = "Instance size of cv server. Set in tfvars file by terraform init script."
}

variable "instance_type_nginx" {
  default     = ""
  description = "Instance size of nginx server. Set in tfvars file by terraform init script."
}

variable "instance_type_bastion" {
  default     = "t2.micro"
  description = "Instance size of bastion server. Set in tfvars file by terraform init script."
}

variable "rds_instance_type" {
  default     = ""
  description = "Instance size of RDS database. Set in tfvars file by terraform init script."
}

# Backups
variable "efs_backup_schedule" {
  description = "Cron expression scheduling EFS backups"
  default     = "cron(0 * * * ? *)"
}

variable "efs_backup_start_window" {
  description = "EFS shared file-system backup start window (minutes)"
  default     = 60
}

variable "efs_backup_completion_window" {
  description = "EFS shared file-system backup completion window (minutes)"
  default     = 120
}

variable "efs_backup_lifecycle_delete_after" {
  description = "EFS lifecycle number of days after creation that a recovery point is deleted"
  default     = 7
}

variable "postgres_snapshot_schedule" {
  description = "Cron expression scheduling postgres backups"
  default     = "cron(15 */2 * * ? *)"
}

# ELK parameters

variable "elk_vpc" {
  description = "VPC for ELK on SST account"
  default     = ""
}

variable "elk_subnet" {
  description = "subnet where Logstash resides (SST account)"
  default     = "172.16.3.0/24"
}

variable "elk_in_use" {
  description = "do we need ELK for this VPC"
  default     = 1
}

variable "elk_count" {
  type = map(string)

  default = {
    is  = 1
    not = 0
  }
}

# Accounts
variable "sst_account_id" {
  default     = ""
  description = "SST AWS Account ID"
}

variable "tfstate_bucket_name" {
  default = ""
}

variable "deployment_solution_s3_bucket_prefix" {
  description = "prefix for naming a deployment solution bucket."
  default     = "axiom-solution-deployment"
}

/*
variable "enable_sst_jenkins_access" {
  description = "specify whether jenkins on sst should be whitelisted(1 or blacklisted 0) to access solution deployment s3 bucket"
  default     = 1
}

variable "role_arn_sst_jenkins_access" {
  description = "Jenkins accesses customer account resources via this role"
  default     = "arn:aws:sts::666123390421:assumed-role/s3-data-transfer-role/copy-session"
}
*/

# The AWS profile to use for the customer environment, should be "<customer_name>-<environment_name>".
variable "env_aws_profile" {
  default = "<customer_name>-<environment_name>"
}

# The AWS profile for SST, should be "sst".
variable "sst_aws_profile" {
  default = "sst"
}

variable "cross_account_route53_role_arn" {
  default = ""
}

variable "axcloud_domain" {
  default = "axcloud.io"
}

# Customer VPN Connection
variable "enable_vpn_access" {
  default = "false"
}

variable "aws_asn_side" {
  default = "64512"
}

#fix for kms in ap-southeast-1c
variable "use_2az" {
  default     = ""
  description = "1 for 2az, 0 for 3az"
}

variable "jdk_version" {
  description = "The version of JDK to install"
  default     = "jdk-8u171-linux-x64.rpm"
}

variable "spot_price" {
  description = "spot price to use spot instance"
  default     = "0.065"
}

variable "jenkins_env" {
  description = "default environment to use spot instance, not in production"
  default     = "development"
}

variable "jenkins_env_short" {
  description = "default jenkins short name i.e. dev or stage or prod"
  default     = "dev"
}

#variable for enabling ssh access
variable "ssh_access" {
  default = "false"
}

#variable for enabling password output
variable "output_sensitive_password" {
  default = "false"
}

# Set to 60 seconds (1 minute) interval as default
variable "rds_enhance_monitor_interval" {
  default = "60"
}

variable "toggle_enhance_monitr" {
  default = 1 # Set to 1 to TURN ON RDS Enhanced Monitoring
}

variable "customer_domain" {
  default = "axiomsl.com"
}

variable "infra_domains" {
  type    = list(string)
  default = ["axiomsl.com"]
}

# DI environment deployment variables 
variable "service_type" {
  default = ""
}

variable "saas_env" {
  default = ""
}

variable "saas_customer" {
  default = ""
}

# Logstash Host 
variable "logstash_host" {
  default = "172.16.3.100:5044"
}

# CV max heap size
variable "instance_type_cv_xmx" {
  default = "4"
}

# Tomcat max heap size
variable "instance_type_tomcat_xmx" {
  default = "4"
}

# RDS Memory 
variable "shared_buffers" {
  default = "0"
}

# CV attached volume size
variable "cv_vol_size" {
  default = "10"
}

# CV attached logs volume size
variable "cv_log_vol_size" {
  default = "10"
}

# CV attached volume size
variable "cv_root_vol_size" {
  default = "30"
}

# Tomcat attached volume size
variable "tomcat_vol_size" {
  default = "10"
}

# Tomcat attached logs volume size
variable "tomcat_log_vol_size" {
  default = "10"
}

variable "quote_comma_quote" {
  default = "\",\""
}

variable "cv_s3_policy_ip_list" {
  type    = list(string)
  default = []
}

variable "enable_migration_peering" {
  default = "false"
}

# vpn on static routes, applies to all vpns of customer
#variable "vpn_static_routes" {
#  default = "true"
#}
# use transit gateway vpn
variable "use_transit_gateway" {
  default = "false"
}

# transit gatway owner profile
variable "vpnowner_aws_profile" {
  default = "var.env_aws_profile"
}

# Environment account id
variable "env_account_id" {
  default = ""
}

variable "vpnowner_account_id" {
  default = ""
}

variable "r_package_mapper" {
  default = "Others"
}

variable "r_package_install_list" {
  default = ""
}

variable "customer_timezone" {
  default = "UTC"
}

variable "customer_adfs_identifier" {
  default = ""
}

variable "customer_ldap_ip" {
  default = ""
}

variable "customer_directory_name" {
  default = ""
}

variable "switch_saml" {
  default = ""
}

variable "logz_enable" {
  default = "true"
}

variable "cv_log_level" {
  default = "INFO"
}

variable "enable_outbound_transfer" {
  default = "false"
}

variable "metric_namespace" {
  default = "cis-global-metrics"
}

variable "efs_throughput_mode" {
  description = "Throughput mode for the file system. Defaults to bursting. Valid values: `bursting`, `provisioned`. When using `provisioned`, also set `provisioned_throughput_in_mibps`"
  default     = ""
}

variable "efs_provisioned_throughput" {
  default     = ""
  description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with `throughput_mode` set to provisioned"
}

variable "enable_citrixservices" {
  default = "false"
}

variable "citrixservices_region" {
  default = "eu-west-1"
}

variable "citrixservices_account_id" {
  description = "Citrix services AWS Account ID"
  default     = ""
}

variable "citrixservices_vpc_id" {
  description = "Citrix services VPC ID"
  default     = ""
}

variable "citrixservices_vpc_cidr_block" {
  description = "Citrix services VPC CIDR block"
  default     = ""
}

variable "citrixservices_sg_vda_id" {
  description = "Citrix services VDA SG ID"
  default     = ""
}

variable "citrixservices_route_table_ids" {
  description = "Citrix services private route tables IDs"
  type        = list(string)
  default     = []
}

variable "dbsources" {
  type    = map(string)
  default = {}
}

variable "enable_cv_archive_via_s3" {
  # 0 disabled, 1 enabled
  default = 0
}

variable "start_cv" {
  default = "true"
}

variable "recreate_cv_schema" {
  default = "false"
}

variable "axiom_init" {
  default = "false"
}

variable "enable_worm_compliance" {
  default = "false"
}

variable "worm_compliance_days" {
  # 6 years
  default = "2190"
}

variable "enable_data_lineage" {
  #false by default, enabled via deploy-infra for new and update-cv-env-settings for existing envs
  default = "false"
}

variable "reset_meta_usrs_paswd" {
  #false by default, reset via rst-db-scema-usrpaswd pipeline for existing envs to re-generate meta users password
  default = "false"
}

variable "blacklisted_cv_tag" {
  default = "runStatement"
}

variable "override_classes" {
  default = "false"
}

variable "override_services" {
  default = "false"
}

variable "whitelist_classes" {
  default = ""
}

variable "whitelist_services" {
  default = ""
}

variable "role_on_target_account" {
  default = ""
}

################Aurora specific variables-BEGIN##############
variable "aurora_db_engine" {
  #expected to be one of [aurora, aurora-mysql, aurora-postgresql]
  default = "aurora-postgres"
}

variable "aurora_db_engine_version" {
  #from deploy-infra dropdown
  default = ""
}

variable "aurora_db_instance_class" {
  default = ""
}

variable "enable_aurora" {
  #set via the deploy-infra pipeline - for new installations
  default = "false"
}

variable "global_cluster_identifier_suffix" {
  default = "gci"
}

variable "engine_mode" {
  #Valid values: global, multimaster, parallelquery, provisioned, serverless; Default=provisioned
  default = "provisioned"
}

#variable enabled_cloudwatch_logs_exports {
#  #The following log types are supported: audit, error, general, slowquery,postgresql
#  type = "list"
#  default = ["error", "general", "slowquery","postgresql"]
#}

variable "replica_scale_enabled" {
  #Whether to enable autoscaling for RDS Aurora (MySQL) read replicas
  default = false
}

variable "replica_scale_min" {
  #Minimum number of replicas to allow scaling for
  default = 1
}

variable "replica_count" {
  #Number of reader nodes to create. If replica_scale_enable is true, the value of replica_scale_min is used instead.
  default = 1
}

variable "performance_insights_enabled" {
  #Specifies whether Performance Insights is enabled or not.
  default = true
}

variable "ca_cert_identifier" {
  #The identifier of the CA certificate for the DB instance
  #this is not used anymore, optional parameter
  default = "rds-ca-2019"
}

variable "aurora_id_prefix" {
  #prefix cluster and cluster instance identofier with this text in case customer
  #name starts with a number
  default = "ax"
}

################Aurora specific variables-END##############
variable "db_local_admin_user" {
  default = " "
}

variable "db_axiom_meta_user" {
  default = " "
}

variable "db_axiom_meta_ro_user" {
  default = " "
}

variable "db_axiom_ro_user" {
  default = " "
}

###########occ related variables begin#############
variable "enable_occ_file_share" {
  default = "false"
}

##below two for testing, update to orig name, once done with Unit testing
#variable occ_s3_bucket_prefix {default="occ"}
variable "occ_env_tag" {
  default = " "
}

variable "occ_sns_topic_name" {
  default = "occ-master-topic"
}

#variable occ_sns_topic_name {default="occ-master-topic"}
variable "occ_sns_topic_region" { #always euws1
  default = "eu-west-1"
}

variable "occ_sst_role_name" {
  # Role on SST account, assumed by customer lambda to download OCC files into customer data bucket
  default = "occ-assume-role-access"
}

#arn=fetch sst account# from the sst_account_id tf variable
############occ related variables end#############

variable "cv_wlog_retention_period" {
  default     = ""
  description = "CV workflow logs retention period"
}

variable "log_retention_period" {
  default     = ""
  description = "CV and Tomcat logs retention period"
}

variable "cv_ui_retention_period" {
  default     = ""
  description = "CV UI logs retention period"
}

#####################AWS workspacespecific vars Begin#############
variable "enable_workspaces" { default = "false" }
variable "aws_managed_directory" { default = "false" } #future option maybe true
variable "aws_managed_ad_type" { default = "MicrosoftAD" }
variable "aws_managed_ad_edition" { default = "Standard" }
variable "internal_sec_cidr_start1" {
  default     = ""
  description = "First three segments of the secondary internal CIDR"
}
variable "internal_sec_cidr_start2" {
  default     = ""
  description = "Next three segments of the secondary internal CIDR (not used as of 1.23)"
}
variable "workspace_bundle_id" {}
#####################AWS workspacespecific vars End###############
#################tf12 warning variables##################
variable "max_parallel_workers" {}
#variable "CV10USR1" {}
variable "temp_buffers" {}
#variable "CV10USR" {}
variable "max_locks_per_transaction" {}
variable "min_wal_size" {}
variable "effective_cache_size" {}
variable "work_mem" { ## leave this as a single line for replacement by init_tf.py; default value is Postgres default -->4Mb
}
variable "maintenance_work_mem" { ## default value is Postgres default --> 64Mb
}
#variable "shared_buffers" { ## default value is Postgres default --> 128Mb
#}
variable "max_worker_processes" { ## default value is Postgres default --> 8
}
variable "max_wal_size" { ## default value is Postgres default --> 1024Mb
}
variable "random_page_cost" { ## default value is Postgres default --> 4
}
variable "default_statistics_target" {
  default = "500"
}
variable "enable_nestloop" {
  default = "1"
}

variable "autovacuum" {
  default = "1"
}

variable "checkpoint_timeout" {
  default = "900"
}

variable "synchronous_commit" {
  default = "on"
}

variable "wal_buffers" {
  default = "2048"
}


# NLB attribute
variable "enable_del_protection" {
  default = true
}
variable "higher_environments" {
  type = list(object({
    environment_name       = string
    environment_account_id = string
  }))
  default = [
  ]
}

variable "lower_environments" {
  type = list(object({
    environment_name       = string
    environment_account_id = string
  }))
  default = [
  ]
}

variable "use_datascope_refinitiv" {
  default = "false"
}

variable "refinitiv_proxy_port" {
  default     = "443"
  description = "Datascope Refinitiv integration application ha-proxy port"
}

variable "enable_service_monitoring" {
  default     = "false"
  description = "Enable monitoring of CV workflow related metrics, i.e. workflow running time"
}

variable "monitoring_api" {
  description = "Whether to send the service monitoring metrics to Logzio or Datadog"
  default     = "logzio"
}

variable "monitor_workflow_execution" {
  default     = "false"
  description = "Monitor whether workflows start execution at a certain time of the day"
}

variable "monitor_workflow_execution_cron" {
  description = "Cron expression schedule for workflow execution monitoring"
  default     = "cron(0 0/1 ? * * *)"
}

variable "enable_rest" {
  default = "false"
}

variable "enable_archive_audit" {
  default = "false"
}

variable "archive_audit_cron" {
  description = "Cron expression scheduling  for archive-audit-task lambda"
  default     = "cron(0/60 * * * ? *)"
}

variable "archive_audit_project_name" {
  default = ""
}
variable "archive_audit_branch_name" {
  default = ""
}
variable "archive_audit_wf_name" {
  default = ""
}

variable "archive_audit_var_projectname" {
  default = ""
}

variable "archive_audit_var_branchname" {
  default = ""
}

variable "ebs_backup_schedule" {
  description = "Cron expression scheduling EBS backups"
  default     = "cron(0 0/2 ? * * *)"
}

variable "ebs_snapshot_cleanup_schedule" {
  description = "Cron expression scheduling EBS snapshot cleanup"
  default     = "cron(5 0 */2 * ? *)"
}

variable "min_days_retention" {
  description = "The time in DAYS for which to keep EBS snapshots"
  default     = "7"
}

variable "enable_oci_db" {
  description = "Enables OCI database use"
  type        = string
  default     = "false"
}

variable "is_sysdb_postgres_oci" {
  description = "Is systems schema AWS postgres"
  type        = string
  default     = "true"
}

variable "vcn_cidr" {
  description = "OCI Customer VCN parent net CIDR. Retrieved from customer_config table"
  type        = string
  default     = " "
}

variable "oci_db_port" {
  description = "OCI autonomous database port"
  type        = number
  default     = 1522
}

variable "first_oci_dbsource_user" {
  description = "Holds the username of the OCI DB user used to create the first DBsource for a given env, default to DDB null"
  type        = string
  default     = " "
}

variable "oci_mtu_size" {
  description = "To be updated only for OCI enabled deployments, default value 9001 for eth0 i/f"
  type        = string
  default     = "1500"
}

# For OCI DB
variable "db_instance_identifier" {
  default = "1"
}
variable "is_prod" {
  default = false
}

variable "enable_snowflake" {
  description = "Enable Snowflake resources"
  default     = "false"
}

variable "sf_vpc_endpoint" {
  description = "Snowflake VPC Endpoint"
  default     = ""
}

variable "sf_whitelist_privatelink" {
  description = "Hostnames and port numbers for Snowflake PrivateLink connectivity"
  type = list(object({
    host = string
    type = string
    port = string
  }))
  default = []
}

variable "sf_dbsources" {
  description = "List of Snowflake CV DBSources"
  type = list(object({
    dbsource_name = string
    sf_db         = string
    sf_schema     = string
  }))
  default = []
}

variable "app_metrics_dd_proxy_port" {
  description = "Port used for sending application metrics"
  default     = "3838"
}

######################## LOGZ.IO CONFIG START ########################
variable "logzio_listener_host" {
  description = "Listener host for Logz.io account"
}

variable "logzio_proxy_host" {
  description = "Proxy host for Logz.io integration"
}

variable "logs_logzio_port" {
  description = "Port used for sending logs to Logz.io"
  default     = "5015"
}

variable "logs_logzio_token" {
  description = "Logz.io logs shipping token"
}

variable "app_metrics_logzio_port" {
  description = "Port used for sending application metrics to Logz.io"
  default     = "8053"
}

variable "metrics_logzio_token" {
  description = "Logz.io metrics shipping token"
}

variable "enable_app_metrics_monitoring" {
  description = "Enable sending of CV application metrics to Logz.io"
}
######################## LOGZ.IO CONFIG END ##########################

variable "enable_webproxy" {
  type        = string
  description = "Enable webproxy resources"
  default     = "false"
}

variable "webproxy_username" {
  type        = string
  description = "Default Squid webproxy username"
  default     = "external"
}

variable "webproxy_port" {
  type        = number
  description = "WebProxy default port"
  default     = 3128
}

variable "enable_sftp_transfer" {
  default = "false"
}

variable "mft_app_region" {
  default = ""
}

variable "web_proxy_nat_eips_mft_region" {
}

variable "enable_mvt_access" {
  description = "To enable access from CV10 to CV9 env"
  default     = "false"
}

variable "target_cv9_env_vpc_cidr" {
  description = "Target CV9 env VPC CIDR block"
  default     = "192.168.16.0/22"
}

variable "target_cv9_env_server_ip" {
  description = "Target CV9 env server IP"
  default     = "192.168.17.100"
}

variable "target_cv9_env_server_port" {
  default     = "443"
  description = "Target CV9 env server port"
}

variable "target_cv9_env_db_ip" {
  description = "Target CV9 env DB IP"
  default     = "192.168.17.110"
}

variable "target_cv9_env_db_port" {
  default     = "1521"
  description = "Target CV9 env DB port"
}

variable "enable_byok" {
  default     = "false"
  description = "to enable/disable byok"
}

variable "enable_pgp" {
  default     = "false"
  description = "to enable/disable pgp ff"
}

variable "enable_env_health_check" {
  default     = "false"
  description = "To enable/disable env health check from Route53"
}

variable "env_health_check_schedule" {
  description = "Cron expression scheduling iac tests lambda execution"
  default     = "cron(0/5 * * * ? *)"
}

variable "env_health_check_count_metric" {
  description = "Environment health check metric"
  default     = "EnvHealthCheckCount"
}

variable "oci_env_health_check_count_metric" {
  description = "Environment health check metric"
  default     = "OCIEnvHealthCheckCount"
}

variable "map_tag_key" {
  default     = ""
  description = "map_tagging key"
}

variable "map_tag_value" {
  default     = ""
  description = "map_tagging value"
}
