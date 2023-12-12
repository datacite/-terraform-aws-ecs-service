variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "app_name" {
    type = "string"
    description = "Name of the application e.g. client-api"
}

variable "env" {
    type = "string"
    description = "Environment prod|stage|test"
}

variable "vpc_id" {}

variable "desired_container_count" {
    type = "string"
}

variable "setup_alb" {
    type = "bool"
    default = true
}

variable "lb_name" {
    type = "string"
    default = "lb-${var.env}"
}

variable "security_group_ids" {
    description = "Security group IDs for the ECS tasks."
    type = list(string)
}

variable "subnet_ids" {
  description = "Subnet IDs for the ECS tasks."
  type        = list(string)
}

variable "container_port" {
    type = "number"
    default = 80
}

variable "launch_type" {
    type = "string"
    default = "FARGATE"
}

variable "health_check_path" {
  type        = string
  description = "The path to the health check endpoint"
  default     = "/heartbeat"
}

variable "namespace_id" {
    type = "string"
}

variable "lb_priority" {
    type = "number"
    default = 1
}

variable "dns_record_name" {
    type = "string"
    description = "Fully qualified domain name for the record i.e. api.datacite.org"
}

variable "ttl" {
  default = "300"
}

variable "use_fargate" {
    type        = bool
    description = "Whether to use Fargate or EC2 for the ECS service"
    default     = true
}

variable "fargate_cpu" {
    type        = string
    description = "The number of cpu units used by the task. If the requires_compatibilities is FARGATE this field is required."
    default     = "256"
}

variable "fargate_memory" {
    type        = string
    description = "The amount (in MiB) of memory used by the task. If the requires_compatibilities is FARGATE this field is required."
    default     = "256"
}

variable "container_definitions" {
    type        = string
    description = "The container definitions as a JSON document. Default is a simple nginx container if unspecified"
    default     = ""
}

variable "managed_externally" {
    type        = bool
    description = "Whether the task definition is managed externally or not. If true then task definition changes are ignored when creating the service"
    default     = false
}