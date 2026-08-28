# variables.tf
#
# BEGINNER NOTE: this module takes networking and IAM as INPUTS (via
# vpc_id, subnet_ids, task_role_arn) rather than creating its own --
# that's the "compose don't duplicate" principle from the brief:
# "the platform should make sensible networking and IAM configurations
# AVAILABLE to workloads" -- it wires them together, it doesn't
# reinvent them.

variable "project" {
  type        = string
  description = "Short project/platform name, used in naming."
}

variable "environment" {
  type        = string
  description = "Environment name: dev or prod."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "owner_team" {
  type        = string
  description = "Team that owns this service, used for tagging."
}

variable "service_name" {
  type        = string
  description = "Short, specific name for this service, e.g. 'web-app', 'ingest-api'."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID -- typically module.networking.vpc_id from the calling environment."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs to run tasks in -- typically module.networking.private_subnet_ids. Private subnets are strongly preferred; tasks reach the internet (if needed) via NAT, not a public IP."
}

variable "container_image" {
  type        = string
  description = "Full container image URI, e.g. '<account>.dkr.ecr.<region>.amazonaws.com/my-app:latest'."
}

variable "container_port" {
  type        = number
  description = "Port the container listens on."
  default     = 8080
}

variable "cpu" {
  type        = number
  description = "Fargate task CPU units (256, 512, 1024, 2048, 4096)."
  default     = 256
}

variable "memory" {
  type        = number
  description = "Fargate task memory in MiB (must pair validly with cpu -- see AWS Fargate task size docs)."
  default     = 512
}

variable "desired_count" {
  type        = number
  description = "Number of task copies to keep running."
  default     = 1
}

variable "task_role_arn" {
  type        = string
  description = "Optional IAM role ARN granting the APPLICATION its permissions (e.g. S3 access) -- typically built via the iam module in the calling environment. Null means the task has no AWS permissions beyond what the execution role needs."
  default     = null
}

variable "ingress_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to reach the container port. Defaults to the VPC's own range only -- override explicitly to open more broadly (e.g. from a load balancer's security group in a future iteration)."
  default     = []
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days -- cost-conscious default, not indefinite retention."
  default     = 30
}
