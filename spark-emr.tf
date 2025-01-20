locals {
  # construct capacity-scheduler configuration
  exe_task_group_configs = var.enable_spark == "true" && var.exe_create_custom_task_instance_groups ? jsondecode(var.exe_task_group_configs) : []
  exe_task_groups_label = join("~", [for tg in local.exe_task_group_configs: tg.label])
  node_labels = [for tg in local.exe_task_group_configs: format("yarn.scheduler.capacity.root.accessible-node-labels.%s.capacity", tg.label)]
  default_node_labels = [for tg in local.exe_task_group_configs: format("yarn.scheduler.capacity.root.default.accessible-node-labels.%s.capacity", tg.label)]
  scheduler_properties = {
    for prop in concat(local.node_labels, local.default_node_labels):
    prop => "100"
  }
  capacity_scheduler = merge({Classification = "capacity-scheduler"}, {Properties = local.scheduler_properties})
  # calculate max memory
  emr_instance_types = jsondecode(file("${path.module}/config/ec2_instances.json"))
  task_group_instance_types = [for tg in local.exe_task_group_configs: tg.task_instance_group_instance_type]
  mem_sizes = [for s in local.emr_instance_types["instance_class"]: s.memory if contains(local.task_group_instance_types, s.class_name)]
  vcores = [for s in local.emr_instance_types["instance_class"]: s.ncpu if contains(local.task_group_instance_types, s.class_name)]
  # if non-existent on ec2_instances.json, default it to 8192 MiB and 2 vCPUs
  max_mem_size = length(local.mem_sizes) > 0 ? max(local.mem_sizes...) * 1024 : 8192
  max_vcores = length(local.vcores) > 0 ? max(local.vcores...) : 2
  # construct yarn-site configuration
  yarn_site_properties = {for c in (var.enable_spark == "true" ? jsondecode(var.exe_configurations_json) : []) : "Properties" => merge(c.Properties, (var.exe_enable_task_instance_group_label ? {
    "yarn.node-labels.enabled" = "true"
  } : {}), {
    "yarn.nodemanager.resource.memory-mb" = tostring(local.max_mem_size),
    "yarn.nodemanager.resource.cpu-vcores" = tostring(local.max_vcores),
    "yarn.scheduler.maximum-allocation-mb"= tostring(local.max_mem_size),
    "yarn.scheduler.maximum-allocation-vcores" = tostring(local.max_vcores)
  }) if c.Classification == "yarn-site"}
  # derive execution configurations json
  exe_configurations_json = jsonencode(concat([for c in (var.enable_spark == "true" ? jsondecode(var.exe_configurations_json) : []) : c if c.Classification != "yarn-site"],
    [merge({Classification = "yarn-site"}, local.yarn_site_properties)], [local.capacity_scheduler]))

  # R packages
  r_packages_spark = var.exe_r_libs_override ? var.exe_r_libs : var.r_package_install_list

  # bootstrap actions
  exe_node_label = var.exe_node_label == "" ? (var.exe_enable_task_instance_group_label ? local.exe_task_groups_label : "SPARK_DRIVER~SPARK_EXECUTORS") : var.exe_node_label
  common_action = {
    path = "s3://${var.aws_region}.elasticmapreduce/bootstrap-actions/run-if"
    name = "runIfmaster"
    args = ["instance.isMaster=true", "touch /tmp/master_node"]
  }
  slave_action = {
    #path = "s3://${aws_s3_bucket.client-bucket.id}/spark/scripts/common/bootstraps/slave_bootstrap.sh"
    path = "s3://${aws_s3_bucket.client-bucket.id}/spark/scripts/common/bootstraps/slave_bootstrap.sh"
    name = "slave_script"
    args = ["cluster_name=${var.namespace}-${var.stage}-${var.name}-exe-${var.env_aws_profile}", "region=${var.aws_region}", "regcloud_install_bucket=${aws_s3_bucket.client-bucket.id}", "repo=${var.exe_r_repo}", "packages=${local.r_packages_spark}", "r_target_groups=${var.exe_r_target_groups}"]
  }
  exe_bootstrap_action = [
    local.common_action,
    local.slave_action,
    {
      path = "s3://${aws_s3_bucket.client-bucket.id}/spark/scripts/common/bootstraps/master_bootstrap.sh"
      name = "copy_scripts"
      args = ["${var.namespace}-${var.stage}-${var.name}-exe-${var.env_aws_profile}", "gw", var.gateway_listener_port, var.exe_gateway_version, var.aws_region, var.mq_protocol, var.spark_version, var.gw_ssl_enabled, var.gw_ssl_client_auth, var.exe_release_label, local.exe_node_label, aws_s3_bucket.client-bucket.id]
    }
  ]
  thrift_bootstrap_action = [
    local.common_action,
    {
      path = "s3://${aws_s3_bucket.client-bucket.id}/spark/scripts/common/bootstraps/master_bootstrap.sh"
      name = "install_thrift"
      args = ["thrift-vanilla", "${var.namespace}-${var.stage}-${var.name}-thrift-${var.env_aws_profile}", var.aws_region, aws_s3_bucket.client-bucket.id]
    }
  ]

  # Glue database name
  glue_db_name = replace(join("_", [var.namespace, var.env_aws_profile, var.aws_region, "emr_execution_data"]), "-", "_")
}

# audit log cannot be configured for RabbitMQ option
# encryptionOptions not supported for RabbitMQ
# use existing security groups for restrictive security group rules
module "exe_mq_broker" {
  #source  = "cloudposse/mq-broker/aws"
  #version = "0.5.1"
  source                       = "./modules/terraform-aws-mq-broker-0.5.1"
  enabled                      = var.enable_spark == "true" ? true : false
  namespace                    = var.namespace
  stage                        = var.stage
  name                         = "${var.name}-mq-${var.env_aws_profile}"
  apply_immediately            = true
  auto_minor_version_upgrade   = false
  deployment_mode              = var.mq_deployment_mode
  engine_type                  = var.mq_broker_engine_type
  engine_version               = var.mq_broker_engine_version
  host_instance_type           = var.mq_broker_host_instance_type
  kms_ssm_key_arn              = aws_kms_key.ssm.arn
  ssm_path                     = "${var.customer}/${var.env}/spark"
  publicly_accessible          = false
  general_log_enabled          = true
  audit_log_enabled            = false
  use_existing_security_groups = true
  existing_security_groups     = var.enable_spark == "true" ? [aws_security_group.mq_broker[0].id] : []
  encryption_enabled           = false
  use_aws_owned_key            = false
  vpc_id                       = aws_vpc.main.id
  subnet_ids                   = var.mq_deployment_mode == "SINGLE_INSTANCE" ? [aws_subnet.app_a.id] : [aws_subnet.app_a.id, aws_subnet.app_b.id]
  mq_application_user          = var.mq_username
  mq_application_password      = var.mq_password
}

resource "aws_route53_record" "exe_mq_record" {
  count   = var.enable_spark == "true" ? 1 : 0
  zone_id = aws_route53_zone.internal.zone_id
  name    = "external-execution-mq"
  type    = "CNAME"
  ttl     = "60"
  #records = ["b-9f0a5c79-e384-4e1c-916f-e39d0e9a0d3d.mq.eu-west-1.amazonaws.com"]
  records = ["${module.exe_mq_broker.broker_id}.mq.${var.aws_region}.amazonaws.com"]
}

module "exe_s3_log_storage" {
  source        = "cloudposse/s3-log-storage/aws"
  version       = "0.15.1"
  enabled       = var.enable_spark == "true" ? true : false
  namespace     = var.namespace
  stage         = var.stage
  name          = "${var.name}-exe-${var.env_aws_profile}"
  attributes    = ["logs"]
  force_destroy = true
}

module "thrift_s3_log_storage" {
  source        = "cloudposse/s3-log-storage/aws"
  version       = "0.15.1"
  enabled       = var.enable_spark == "true" ? true : false
  namespace     = var.namespace
  stage         = var.stage
  name          = "${var.name}-thrift-${var.env_aws_profile}"
  attributes    = ["logs"]
  force_destroy = true
}

resource "aws_key_pair" "spark_cluster_key" {
  count      = var.enable_spark == "true" ? 1 : 0
  key_name   = "spark_pub_key-${var.env_aws_profile}"
  public_key = data.aws_s3_bucket_object.ec2_ssh_public_key.body
  tags = {
    Name        = "spark_pub_key-${var.env_aws_profile}"
    customer    = var.customer
    Environment = var.env
  }
}

# a common security configuration for both execution and Thrift cluster
# emr data s3 bucket will overwrite with its own CSE-KMS
resource "aws_emr_security_configuration" "emr_sec_conf" {
  count = var.enable_spark == "true" ? 1 : 0
  name  = "${var.namespace}-${var.stage}-${var.name}-${var.env_aws_profile}"

  configuration = <<EOF
{
  "EncryptionConfiguration": {
    "AtRestEncryptionConfiguration": {
      "S3EncryptionConfiguration": {
        "EncryptionMode": "SSE-KMS",
        "AwsKmsKey": "${aws_kms_key.emr_staging[0].arn}",
        "Overrides": [
          {
            "BucketName": "${aws_s3_bucket.emr_execution_data_bucket[0].bucket}",
            "EncryptionMode": "CSE-KMS",
            "AwsKmsKey": "${aws_kms_key.emr_data[0].arn}"
          }
        ]
      }
    },
    "EnableInTransitEncryption": false,
    "EnableAtRestEncryption": true
  }
}
EOF
}

module "exe_emr_cluster" {
  # source = "cloudposse/emr-cluster/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version                                        = "0.15.0"
  # custom 0.15.0 with additional endpoint security groups id for egress due to unsupported latest module versions
  source                                         = "./modules/terraform-aws-emr-cluster-0.15.0"
  enabled                                        = var.enable_spark == "true" ? true : false
  namespace                                      = var.namespace
  stage                                          = var.stage
  name                                           = "${var.name}-exe-${var.env_aws_profile}"
  master_allowed_security_groups                 = var.enable_spark == "true" ? [aws_security_group.bastion.id, aws_security_group.cv.id, aws_security_group.tomcat.id] : []
  slave_allowed_security_groups                  = []
  region                                         = var.aws_region
  vpc_id                                         = aws_vpc.main.id
  subnet_id                                      = var.exe_availability_zone == "zone_a" ? aws_subnet.app_a.id : aws_subnet.app_b.id
  route_table_id                                 = aws_route_table.nat-route1a[0].id
  subnet_type                                    = var.subnet_type
  ebs_root_volume_size                           = var.exe_ebs_root_volume_size
  visible_to_all_users                           = var.exe_visible_to_all_users
  release_label                                  = var.exe_release_label
  applications                                   = var.exe_applications
  create_vpc_endpoint_s3                         = var.create_vpc_endpoint_s3
  configurations_json                            = var.exe_enable_task_instance_group_label ? local.exe_configurations_json : var.exe_configurations_json
  core_instance_group_instance_type              = var.exe_core_instance_group_instance_type
  core_instance_group_instance_count             = var.exe_core_instance_group_instance_count
  core_instance_group_ebs_size                   = var.exe_core_instance_group_ebs_size
  core_instance_group_ebs_type                   = var.exe_core_instance_group_ebs_type
  core_instance_group_ebs_volumes_per_instance   = var.exe_core_instance_group_ebs_volumes_per_instance
  core_instance_group_bid_price                  = var.exe_core_instance_group_bid_price
  master_instance_group_instance_type            = var.exe_master_instance_group_instance_type
  master_instance_group_instance_count           = var.exe_master_instance_group_instance_count
  master_instance_group_ebs_size                 = var.exe_master_instance_group_ebs_size
  master_instance_group_ebs_type                 = var.exe_master_instance_group_ebs_type
  master_instance_group_ebs_volumes_per_instance = var.exe_master_instance_group_ebs_volumes_per_instance
  master_instance_group_bid_price                = var.exe_master_instance_group_bid_price
  create_task_instance_group                     = !var.exe_create_custom_task_instance_groups && var.exe_create_task_instance_group
  task_instance_group_instance_type              = var.exe_task_instance_group_instance_type
  task_instance_group_instance_count             = var.exe_task_instance_group_instance_count
  task_instance_group_ebs_size                   = var.exe_task_instance_group_ebs_size
  task_instance_group_ebs_optimized              = var.exe_task_instance_group_ebs_optimized
  task_instance_group_ebs_type                   = var.exe_task_instance_group_ebs_type
  task_instance_group_ebs_volumes_per_instance   = var.exe_task_instance_group_ebs_volumes_per_instance
  task_instance_group_bid_price                  = var.exe_task_instance_group_bid_price
  log_uri                                        = format("s3n://%s/", module.exe_s3_log_storage.bucket_id)
  key_name                                       = var.enable_spark == "true" ? aws_key_pair.spark_cluster_key[0].key_name : null
  bootstrap_action                               = length(var.exe_bootstrap_action) == 0 ? local.exe_bootstrap_action : var.exe_bootstrap_action
  security_configuration                         = var.enable_spark == "true" ? aws_emr_security_configuration.emr_sec_conf[0].name : null
  zone_id                                        = var.enable_spark == "true" ? aws_route53_zone.internal.zone_id : null
  master_dns_name                                = "external-execution-gateway"
  endpoint_security_group_id                     = var.enable_spark == "true" ? aws_security_group.private_endpoints.id : null
  s3_prefix_list                                 = var.enable_spark == "true" ? [aws_vpc_endpoint.s3.prefix_list_id] : []
}

module "thrift_emr_cluster" {
  # source = "cloudposse/emr-cluster/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version                                        = "0.15.0"
  # custom 0.15.0 with additional endpoint security groups id for egress due to unsupported latest module versions
  source                                         = "./modules/terraform-aws-emr-cluster-0.15.0"
  enabled                                        = var.enable_spark == "true" ? true : false
  namespace                                      = var.namespace
  stage                                          = var.stage
  name                                           = "${var.name}-thrift-${var.env_aws_profile}"
  master_allowed_security_groups                 = var.enable_spark == "true" ? [aws_security_group.bastion.id, aws_security_group.cv.id, aws_security_group.tomcat.id] : []
  slave_allowed_security_groups                  = []
  region                                         = var.aws_region
  vpc_id                                         = aws_vpc.main.id
  subnet_id                                      = var.thrift_availability_zone == "zone_a" ? aws_subnet.app_a.id : aws_subnet.app_b.id
  route_table_id                                 = aws_route_table.nat-route1b[0].id
  subnet_type                                    = var.subnet_type
  ebs_root_volume_size                           = var.thrift_ebs_root_volume_size
  visible_to_all_users                           = var.thrift_visible_to_all_users
  release_label                                  = var.thrift_release_label
  applications                                   = var.thrift_applications
  create_vpc_endpoint_s3                         = var.create_vpc_endpoint_s3
  configurations_json                            = var.thrift_configurations_json
  core_instance_group_instance_type              = var.thrift_core_instance_group_instance_type
  core_instance_group_instance_count             = var.thrift_core_instance_group_instance_count
  core_instance_group_ebs_size                   = var.thrift_core_instance_group_ebs_size
  core_instance_group_ebs_type                   = var.thrift_core_instance_group_ebs_type
  core_instance_group_ebs_volumes_per_instance   = var.thrift_core_instance_group_ebs_volumes_per_instance
  core_instance_group_bid_price                  = var.thrift_core_instance_group_bid_price
  master_instance_group_instance_type            = var.thrift_master_instance_group_instance_type
  master_instance_group_instance_count           = var.thrift_master_instance_group_instance_count
  master_instance_group_ebs_size                 = var.thrift_master_instance_group_ebs_size
  master_instance_group_ebs_type                 = var.thrift_master_instance_group_ebs_type
  master_instance_group_ebs_volumes_per_instance = var.thrift_master_instance_group_ebs_volumes_per_instance
  master_instance_group_bid_price                = var.thrift_master_instance_group_bid_price
  create_task_instance_group                     = var.thrift_create_task_instance_group
  task_instance_group_instance_type              = var.thrift_task_instance_group_instance_type
  task_instance_group_instance_count             = var.thrift_task_instance_group_instance_count
  task_instance_group_ebs_size                   = var.thrift_task_instance_group_ebs_size
  task_instance_group_ebs_optimized              = var.thrift_task_instance_group_ebs_optimized
  task_instance_group_ebs_type                   = var.thrift_task_instance_group_ebs_type
  task_instance_group_ebs_volumes_per_instance   = var.thrift_task_instance_group_ebs_volumes_per_instance
  task_instance_group_bid_price                  = var.thrift_task_instance_group_bid_price
  log_uri                                        = format("s3n://%s/", module.thrift_s3_log_storage.bucket_id)
  key_name                                       = var.enable_spark == "true" ? aws_key_pair.spark_cluster_key[0].key_name : null
  bootstrap_action                               = length(var.thrift_bootstrap_action) == 0 ? local.thrift_bootstrap_action : var.thrift_bootstrap_action
  security_configuration                         = var.enable_spark == "true" ? aws_emr_security_configuration.emr_sec_conf[0].name : null
  zone_id                                        = var.enable_spark == "true" ? aws_route53_zone.internal.zone_id : null
  master_dns_name                                = "external-execution-hive"
  endpoint_security_group_id                     = var.enable_spark == "true" ? aws_security_group.private_endpoints.id : null
  s3_prefix_list                                 = var.enable_spark == "true" ? [aws_vpc_endpoint.s3.prefix_list_id] : []
}

# Spark clusters managed scaling policies
resource "aws_emr_managed_scaling_policy" "exe_scaling_policy" {
  count      = var.enable_spark == "true" ? 1 : 0
  cluster_id = module.exe_emr_cluster.cluster_id
  compute_limits {
    unit_type                       = var.exe_scaling_unit_type
    minimum_capacity_units          = var.exe_minimum_capacity_units
    maximum_capacity_units          = var.exe_maximum_capacity_units
    maximum_ondemand_capacity_units = var.exe_maximum_ondemand_capacity_units
    maximum_core_capacity_units     = var.exe_maximum_core_capacity_units
  }
}

resource "aws_emr_managed_scaling_policy" "thrift_scaling_policy" {
  count      = var.enable_spark == "true" ? 1 : 0
  cluster_id = module.thrift_emr_cluster.cluster_id
  compute_limits {
    unit_type                       = var.thrift_scaling_unit_type
    minimum_capacity_units          = var.thrift_minimum_capacity_units
    maximum_capacity_units          = var.thrift_maximum_capacity_units
    maximum_ondemand_capacity_units = var.thrift_maximum_ondemand_capacity_units
    maximum_core_capacity_units     = var.thrift_maximum_core_capacity_units
  }
}

# database referenced at Hive DBSource
resource "aws_glue_catalog_database" "spark_hive_db" {
  count        = var.enable_spark == "true" ? 1 : 0
  name         = local.glue_db_name
  description  = "${var.env_aws_profile} Spark Hive database"
  location_uri = format("s3://%s/", aws_s3_bucket.emr_execution_data_bucket[0].id)
}

# Create execution cluster Custom task instance groups if exe_create_custom_task_instance_groups
resource "aws_emr_instance_group" "custom_label_task_group" {
  for_each = {
    for tg in local.exe_task_group_configs : tg.label => tg
  }

  name       = each.key
  cluster_id = module.exe_emr_cluster.cluster_id

  instance_type  = each.value.task_instance_group_instance_type
  instance_count = each.value.task_instance_group_instance_count

  ebs_config {
    size                 = each.value.task_instance_group_ebs_size
    type                 = each.value.task_instance_group_ebs_type
    #iops                 = each.value.undeclared
    volumes_per_instance = each.value.task_instance_group_ebs_volumes_per_instance
  }

  bid_price           = each.value.task_instance_group_bid_price
  ebs_optimized       = each.value.task_instance_group_ebs_optimized
  configurations_json = jsonencode(each.value.configuration_json)
  autoscaling_policy  = length(each.value.task_instance_group_autoscaling_policy_json) > 0 ? jsonencode(each.value.task_instance_group_autoscaling_policy_json) : null
}

# ----------------------
# CloudWatch EMR Alarms
# ----------------------

resource "aws_cloudwatch_metric_alarm" "exe_run_time_core_node" {
  count               = var.exe_enable_core_nodes_monitoring == "true" && var.enable_spark == "true" ? 1 : 0
  alarm_name          = "EMR_Exe_Core_Nodes_Running-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CoreNodesRunning"
  namespace           = "AWS/ElasticMapReduce"
  period              = var.exe_alarm_core_nodes_running_threshold_period
  statistic           = "Minimum"
  threshold           = var.exe_alarm_core_nodes_running_threshold
  alarm_description   = "EMR - Running more than ${var.exe_alarm_core_nodes_running_threshold} core nodes, for more than ${var.exe_alarm_core_nodes_running_threshold_period} seconds"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Monitor-Notification-${var.customer}-${var.env}"]
  dimensions = {
    JobFlowId = module.exe_emr_cluster.cluster_id
  }
}

resource "aws_cloudwatch_metric_alarm" "exe_run_time_task_node" {
  count               = var.exe_enable_task_nodes_monitoring == "true" && var.enable_spark == "true" ? 1 : 0
  alarm_name          = "EMR_Exe_Task_Nodes_Running-${var.customer}-${var.env}-${var.aws_region}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "TaskNodesRunning"
  namespace           = "AWS/ElasticMapReduce"
  period              = var.exe_alarm_task_nodes_running_threshold_period
  statistic           = "Minimum"
  threshold           = var.exe_alarm_task_nodes_running_threshold
  alarm_description   = "EMR - Running more than ${var.exe_alarm_task_nodes_running_threshold} task nodes, for more than ${var.exe_alarm_task_nodes_running_threshold_period} seconds"
  alarm_actions       = ["arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.env_account.account_id}:Monitor-Notification-${var.customer}-${var.env}"]
  dimensions = {
    JobFlowId = module.exe_emr_cluster.cluster_id
  }
}