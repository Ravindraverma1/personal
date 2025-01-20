variable "mq_broker_engine_type" {
  type        = string
  default     = "RabbitMQ"
  description = "MQ broker engine type"
}

variable "mq_broker_engine_version" {
  type        = string
  default     = "3.8.11"
  description = "MQ broker engine version"
}

variable "mq_broker_host_instance_type" {
  type        = string
  default     = "mq.t3.micro"
  description = "MQ Broker Host instance type"
}

variable "mq_username" {
  type        = string
  default     = "axiom_user"
  description = "MQ username"
}

variable "mq_password" {
  type        = string
  default     = ""
  description = "MQ password"
}

variable "mq_broker_port" {
  type        = number
  default     = 5671
  description = "MQ Broker port"
}

variable "mq_deployment_mode" {
  type        = string
  default     = "SINGLE_INSTANCE"
  description = "The deployment mode of the broker. SINGLE_INSTANCE or ACTIVE_STANDBY_MULTI_AZ"
}

variable "mq_protocol" {
  type        = string
  default     = "amqp"
  description = "MQ protocol"
}
