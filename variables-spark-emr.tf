variable "namespace" {
  type        = string
  description = "Namespace (e.g. `eg` or `cp`)"
  default     = "axiom"
}

variable "stage" {
  type        = string
  description = "Stage (e.g. `prod`, `dev`, `staging`, `infra`)"
  default     = "dev"
}

variable "name" {
  type        = string
  description = "Name  (e.g. `app` or `cluster`)"
  default     = "emr"
}

variable "exe_ebs_root_volume_size" {
  type        = number
  description = "Size in GiB of the EBS root device volume of the Linux AMI that is used for each EC2 instance. Available in Amazon EMR version 4.x and later"
  default     = 10
}

variable "exe_visible_to_all_users" {
  type        = bool
  description = "Whether the job flow is visible to all IAM users of the AWS account associated with the job flow"
  default     = true
}

variable "exe_release_label" {
  type        = string
  description = "The release label for the Amazon EMR release. https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-release-5x.html"
  default     = "emr-5.25.0"
}

variable "exe_applications" {
  type        = list(string)
  description = "A list of applications for the cluster. Valid values are: Flink, Ganglia, Hadoop, HBase, HCatalog, Hive, Hue, JupyterHub, Livy, Mahout, MXNet, Oozie, Phoenix, Pig, Presto, Spark, Sqoop, TensorFlow, Tez, Zeppelin, and ZooKeeper (as of EMR 5.25.0). Case insensitive"
  default     = []
}

# https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-configure-apps.html
variable "exe_configurations_json" {
  type        = string
  description = "A JSON string for supplying list of configurations for the EMR cluster. See https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-configure-apps.html for more details"
  default     = ""
}

variable "subnet_type" {
  type        = string
  description = "Type of VPC subnet ID where you want the job flow to launch. Supported values are `private` or `public`"
  default     = "private"
}

variable "exe_availability_zone" {
  type        = string
  description = "Zone where exe emr will run (e.g. `zone_a`, `zone_b`)"
  default     = "zone_a"
}

variable "thrift_availability_zone" {
  type        = string
  description = "Zone where thrift emr will run (e.g. `zone_a`, `zone_b`)"
  default     = "zone_b"
}

variable "exe_core_instance_group_instance_type" {
  type        = string
  description = "EC2 instance type for all instances in the Core instance group"
  default     = null
}

variable "exe_core_instance_group_instance_count" {
  type        = number
  description = "Target number of instances for the Core instance group. Must be at least 1"
  default     = 1
}

variable "exe_core_instance_group_ebs_size" {
  type        = number
  description = "Core instances volume size, in gibibytes (GiB)"
  default     = 10
}

variable "exe_core_instance_group_ebs_type" {
  type        = string
  description = "Core instances volume type. Valid options are `gp2`, `io1`, `standard` and `st1`"
  default     = "gp2"
}

variable "exe_core_instance_group_ebs_volumes_per_instance" {
  type        = number
  description = "The number of EBS volumes with this configuration to attach to each EC2 instance in the Core instance group"
  default     = 1
}

variable "exe_core_instance_group_bid_price" {
  type        = string
  description = "Bid price for each EC2 instance in the Core instance group, expressed in USD. By setting this attribute, the instance group is being declared as a Spot Instance, and will implicitly create a Spot request. Leave this blank to use On-Demand Instances"
  default     = null
}

variable "exe_master_instance_group_instance_type" {
  type        = string
  description = "EC2 instance type for all instances in the Master instance group"
  default     = null
}

variable "exe_master_instance_group_instance_count" {
  type        = number
  description = "Target number of instances for the Master instance group. Must be at least 1"
  default     = 1
}

variable "exe_master_instance_group_ebs_size" {
  type        = number
  description = "Master instances volume size, in gibibytes (GiB)"
  default     = 10
}

variable "exe_master_instance_group_ebs_type" {
  type        = string
  description = "Master instances volume type. Valid options are `gp2`, `io1`, `standard` and `st1`"
  default     = "gp2"
}

variable "exe_master_instance_group_ebs_volumes_per_instance" {
  type        = number
  description = "The number of EBS volumes with this configuration to attach to each EC2 instance in the Master instance group"
  default     = 1
}

variable "exe_master_instance_group_bid_price" {
  type        = string
  description = "Bid price for each EC2 instance in the Master instance group, expressed in USD. By setting this attribute, the instance group is being declared as a Spot Instance, and will implicitly create a Spot request. Leave this blank to use On-Demand Instances"
  default     = null
}

variable "exe_create_task_instance_group" {
  type        = bool
  description = "Whether to create an instance group for Task nodes. For more info: https://www.terraform.io/docs/providers/aws/r/emr_instance_group.html, https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-master-core-task-nodes.html"
  default     = false
}

variable "exe_task_instance_group_instance_type" {
  type        = string
  description = "EC2 instance type for all instances in the Task instance group"
  default     = null
}

variable "exe_task_instance_group_instance_count" {
  type        = number
  description = "Target number of instances for the Task instance group. Must be at least 1"
  default     = 1
}

variable "exe_task_instance_group_ebs_size" {
  type        = number
  description = "Task instances volume size, in gibibytes (GiB)"
  default     = 10
}

variable "exe_task_instance_group_ebs_optimized" {
  type        = bool
  description = "Indicates whether an Amazon EBS volume in the Task instance group is EBS-optimized. Changing this forces a new resource to be created"
  default     = false
}

variable "exe_task_instance_group_ebs_type" {
  type        = string
  description = "Task instances volume type. Valid options are `gp2`, `io1`, `standard` and `st1`"
  default     = "gp2"
}

variable "exe_task_instance_group_ebs_volumes_per_instance" {
  type        = number
  description = "The number of EBS volumes with this configuration to attach to each EC2 instance in the Task instance group"
  default     = 1
}

variable "exe_task_instance_group_bid_price" {
  type        = string
  description = "Bid price for each EC2 instance in the Task instance group, expressed in USD. By setting this attribute, the instance group is being declared as a Spot Instance, and will implicitly create a Spot request. Leave this blank to use On-Demand Instances"
  default     = null
}

variable "exe_bootstrap_action" {
  type = list(object({
    path = string
    name = string
    args = list(string)
  }))
  description = "List of bootstrap actions that will be run before Hadoop is started on the cluster nodes"
  default     = []
}

variable "exe_create_custom_task_instance_groups" {
  type        = bool
  description = "Set to true to create Execution cluster custom task instance groups"
  default     = true
}

variable "exe_enable_task_instance_group_label" {
  type        = bool
  description = "Set to true to enable Execution cluster task instance group label"
  default     = true
}

variable "exe_task_group_configs" {
  type        = string
  description = "Execution cluster custom task group configurations JSON string"
  default     = "[]"
}

variable "create_vpc_endpoint_s3" {
  type        = bool
  description = "Set to false to prevent the module from creating VPC S3 Endpoint"
  default     = false
}

variable "thrift_ebs_root_volume_size" {
  type        = number
  description = "Size in GiB of the EBS root device volume of the Linux AMI that is used for each EC2 instance. Available in Amazon EMR version 4.x and later"
  default     = 10
}

variable "thrift_visible_to_all_users" {
  type        = bool
  description = "Whether the job flow is visible to all IAM users of the AWS account associated with the job flow"
  default     = true
}

variable "thrift_release_label" {
  type        = string
  description = "The release label for the Amazon EMR release. https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-release-5x.html"
  default     = "emr-5.25.0"
}

variable "thrift_applications" {
  type        = list(string)
  description = "A list of applications for the cluster. Valid values are: Flink, Ganglia, Hadoop, HBase, HCatalog, Hive, Hue, JupyterHub, Livy, Mahout, MXNet, Oozie, Phoenix, Pig, Presto, Spark, Sqoop, TensorFlow, Tez, Zeppelin, and ZooKeeper (as of EMR 5.25.0). Case insensitive"
  default     = []
}

# https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-configure-apps.html
variable "thrift_configurations_json" {
  type        = string
  description = "A JSON string for supplying list of configurations for the EMR cluster. See https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-configure-apps.html for more details"
  default     = ""
}

variable "thrift_core_instance_group_instance_type" {
  type        = string
  description = "EC2 instance type for all instances in the Core instance group"
  default     = null
}

variable "thrift_core_instance_group_instance_count" {
  type        = number
  description = "Target number of instances for the Core instance group. Must be at least 1"
  default     = 1
}

variable "thrift_core_instance_group_ebs_size" {
  type        = number
  description = "Core instances volume size, in gibibytes (GiB)"
  default     = 10
}

variable "thrift_core_instance_group_ebs_type" {
  type        = string
  description = "Core instances volume type. Valid options are `gp2`, `io1`, `standard` and `st1`"
  default     = "gp2"
}

variable "thrift_core_instance_group_ebs_volumes_per_instance" {
  type        = number
  description = "The number of EBS volumes with this configuration to attach to each EC2 instance in the Core instance group"
  default     = 1
}

variable "thrift_core_instance_group_bid_price" {
  type        = string
  description = "Bid price for each EC2 instance in the Core instance group, expressed in USD. By setting this attribute, the instance group is being declared as a Spot Instance, and will implicitly create a Spot request. Leave this blank to use On-Demand Instances"
  default     = null
}

variable "thrift_master_instance_group_instance_type" {
  type        = string
  description = "EC2 instance type for all instances in the Master instance group"
  default     = null
}

variable "thrift_master_instance_group_instance_count" {
  type        = number
  description = "Target number of instances for the Master instance group. Must be at least 1"
  default     = 1
}

variable "thrift_master_instance_group_ebs_size" {
  type        = number
  description = "Master instances volume size, in gibibytes (GiB)"
  default     = 10
}

variable "thrift_master_instance_group_ebs_type" {
  type        = string
  description = "Master instances volume type. Valid options are `gp2`, `io1`, `standard` and `st1`"
  default     = "gp2"
}

variable "thrift_master_instance_group_ebs_volumes_per_instance" {
  type        = number
  description = "The number of EBS volumes with this configuration to attach to each EC2 instance in the Master instance group"
  default     = 1
}

variable "thrift_master_instance_group_bid_price" {
  type        = string
  description = "Bid price for each EC2 instance in the Master instance group, expressed in USD. By setting this attribute, the instance group is being declared as a Spot Instance, and will implicitly create a Spot request. Leave this blank to use On-Demand Instances"
  default     = null
}

variable "thrift_create_task_instance_group" {
  type        = bool
  description = "Whether to create an instance group for Task nodes. For more info: https://www.terraform.io/docs/providers/aws/r/emr_instance_group.html, https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-master-core-task-nodes.html"
  default     = false
}

variable "thrift_task_instance_group_instance_type" {
  type        = string
  description = "EC2 instance type for all instances in the Task instance group"
  default     = null
}

variable "thrift_task_instance_group_instance_count" {
  type        = number
  description = "Target number of instances for the Task instance group. Must be at least 1"
  default     = 1
}

variable "thrift_task_instance_group_ebs_size" {
  type        = number
  description = "Task instances volume size, in gibibytes (GiB)"
  default     = 10
}

variable "thrift_task_instance_group_ebs_optimized" {
  type        = bool
  description = "Indicates whether an Amazon EBS volume in the Task instance group is EBS-optimized. Changing this forces a new resource to be created"
  default     = false
}

variable "thrift_task_instance_group_ebs_type" {
  type        = string
  description = "Task instances volume type. Valid options are `gp2`, `io1`, `standard` and `st1`"
  default     = "gp2"
}

variable "thrift_task_instance_group_ebs_volumes_per_instance" {
  type        = number
  description = "The number of EBS volumes with this configuration to attach to each EC2 instance in the Task instance group"
  default     = 1
}

variable "thrift_task_instance_group_bid_price" {
  type        = string
  description = "Bid price for each EC2 instance in the Task instance group, expressed in USD. By setting this attribute, the instance group is being declared as a Spot Instance, and will implicitly create a Spot request. Leave this blank to use On-Demand Instances"
  default     = null
}

variable "thrift_bootstrap_action" {
  type = list(object({
    path = string
    name = string
    args = list(string)
  }))
  description = "List of bootstrap actions that will be run before Hadoop is started on the cluster nodes"
  default     = []
}

variable "enable_spark" {
  type        = string
  description = "String of boolean value to create Spark-based resources"
  default     = "false"
}

variable "keep_spark_data" {
  type        = string
  description = "String of boolean value to keep Spark-designated execution staging and data S3 buckets"
  default     = "false"
}

variable "gateway_listener_port" {
  type        = number
  default     = 8855
  description = "Execution EMR Gateway HTTP port"
}

variable "hive_listener_port" {
  type        = number
  default     = 10001
  description = "Hive2Server listener port"
}

variable "exe_scaling_unit_type" {
  type        = string
  description = "The unit type used for specifying a managed scaling policy. Valid values: InstanceFleetUnits | Instances | VCPU"
  default     = "Instances"
}

variable "exe_minimum_capacity_units" {
  type        = number
  description = "The lower boundary of EC2 units. It is measured through VCPU cores or instances for instance groups and measured through units for instance fleets. Managed scaling activities are not allowed beyond this boundary. The limit only applies to the core and task nodes. The master node cannot be scaled after initial configuration."
  default     = 1
}

variable "exe_maximum_capacity_units" {
  type        = number
  description = "The upper boundary of EC2 units. It is measured through VCPU cores or instances for instance groups and measured through units for instance fleets. Managed scaling activities are not allowed beyond this boundary. The limit only applies to the core and task nodes. The master node cannot be scaled after initial configuration"
  default     = 2
}

variable "exe_maximum_ondemand_capacity_units" {
  type        = number
  description = "The upper boundary of On-Demand EC2 units. It is measured through VCPU cores or instances for instance groups and measured through units for instance fleets. The On-Demand units are not allowed to scale beyond this boundary. The parameter is used to split capacity allocation between On-Demand and Spot instances."
  default     = 1
}

variable "exe_maximum_core_capacity_units" {
  type        = number
  description = "The upper boundary of EC2 units for core node type in a cluster. It is measured through VCPU cores or instances for instance groups and measured through units for instance fleets. The core units are not allowed to scale beyond this boundary. The parameter is used to split capacity allocation between core and task nodes."
  default     = 1
}

variable "thrift_scaling_unit_type" {
  type        = string
  description = "The unit type used for specifying a managed scaling policy. Valid values: InstanceFleetUnits | Instances | VCPU"
  default     = "Instances"
}

variable "thrift_minimum_capacity_units" {
  type        = number
  description = "The lower boundary of EC2 units. It is measured through VCPU cores or instances for instance groups and measured through units for instance fleets. Managed scaling activities are not allowed beyond this boundary. The limit only applies to the core and task nodes. The master node cannot be scaled after initial configuration."
  default     = 1
}

variable "thrift_maximum_capacity_units" {
  type        = number
  description = "The upper boundary of EC2 units. It is measured through VCPU cores or instances for instance groups and measured through units for instance fleets. Managed scaling activities are not allowed beyond this boundary. The limit only applies to the core and task nodes. The master node cannot be scaled after initial configuration"
  default     = 2
}

variable "thrift_maximum_ondemand_capacity_units" {
  type        = number
  description = "The upper boundary of On-Demand EC2 units. It is measured through VCPU cores or instances for instance groups and measured through units for instance fleets. The On-Demand units are not allowed to scale beyond this boundary. The parameter is used to split capacity allocation between On-Demand and Spot instances."
  default     = 1
}

variable "thrift_maximum_core_capacity_units" {
  type        = number
  description = "The upper boundary of EC2 units for core node type in a cluster. It is measured through VCPU cores or instances for instance groups and measured through units for instance fleets. The core units are not allowed to scale beyond this boundary. The parameter is used to split capacity allocation between core and task nodes."
  default     = 1
}

variable "gw_ssl_enabled" {
  type        = string
  description = "Enables SSL on gateway"
  default     = "true"
}

variable "gw_ssl_client_auth" {
  type        = string
  description = "Force client certificate authentication at gateway"
  default     = "false"
}

variable "exe_gateway_version" {
  type        = string
  description = "Execution Spark Gateway version"
  default     = ""
}

variable "exe_node_label" {
  type        = string
  description = "Execution cluster node label"
  default     = ""
}

variable "exe_enable_core_nodes_monitoring" {
  type        = string
  description = "enable core nodes alarms"
  default     = "true"
}

variable "exe_alarm_core_nodes_running_threshold" {
  type        = string
  description = "Running Core Nodes number greater or equal config variable, will cause an alarm (according also to period variable)"
  default     = 3
}

variable "exe_alarm_core_nodes_running_threshold_period" {
  type        = string
  description = "number of Running Core Nodes (greater or equal to threshold variable) for more than x seconds"
  default     = 21600
}

variable "exe_enable_task_nodes_monitoring" {
  type        = string
  description = "enable core nodes alarms"
  default     = "true"
}

variable "exe_alarm_task_nodes_running_threshold" {
  type        = string
  description = "Running Task Nodes number greater or equal config variable, will cause an alarm (according also to period variable)"
  default     = 3
}

variable "exe_alarm_task_nodes_running_threshold_period" {
  type        = string
  description = "number of Running Task Nodes (greater or equal to threshold variable) for more than x seconds"
  default     = 21600
}

variable "spark_version" {
  type        = string
  description = "Spark version"
  default     = "2.4.8-2-AX"
}

variable "exe_r_repo" {
  type        = string
  description = "R repo to retrieve from, packages to install on slave nodes on bootstrap"
  default     = "cran.us.r-project.org"
}

variable "exe_r_target_groups" {
  type        = string
  description = "Instances Groups where to deploy R packages separated by a comma (DRIVER,EXECUTOR)"
  default     = "DRIVER"
}

variable "exe_r_libs_override" {
  type        = bool
  description = "False if currently configured list for this environment to use, or True if lib list to install needs to be taken from the R_LIBS parameter below."
  default     = true
}

variable "exe_r_libs" {
  type        = string
  description = "List of comma separated R libraries to install in case R_LIBS_OVERRIDE is checked."
  default     = ""
}

