variable "enable_redshift" {
  default = "false"
}

variable "cluster_database_name" {
  default = "redshiftdb"
}

variable "cluster_identifier" {
  default = "redshift-cluster"
}

variable "cluster_master_username" {
  default = "axiom_user"
}

variable "cluster_node_type" {
  default = ""
}

variable "cluster_port" {
  default = "5439"
}

variable "cluster_number_of_nodes" {
  default = ""
}

variable "wlm_json_config" {
  default = ""
}