# variables.tf
#
# BEGINNER NOTE: there is deliberately NO "password" variable here.
# If there were, the caller would have to type a real password into
# a .tf or .tfvars file -- which then sits in git history forever,
# readable by anyone with repo access, essentially permanently. The
# module generates and stores the password itself (see main.tf) so
# a secret never has to pass through a human's fingers or a text file.

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
  description = "Team that owns this database, used for tagging."
}

variable "db_purpose" {
  type        = string
  description = "Short, specific purpose, e.g. 'orders', 'analytics-metadata'. Used in naming."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID -- typically module.networking.vpc_id."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs the DB subnet group will use -- typically module.networking.private_subnet_ids. RDS should never be reachable from public subnets."
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security group IDs allowed to reach the database (e.g. an ECS service's SG). Prefer this over CIDR-based access -- it's more precise and self-documenting about WHO can connect."
  default     = []
}

variable "engine" {
  type        = string
  description = "Database engine: 'postgres' or 'mysql'."
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql"], var.engine)
    error_message = "engine must be 'postgres' or 'mysql'."
  }
}

variable "engine_version" {
  type        = string
  description = "Engine version, e.g. '16.4' for postgres."
  default     = "16.4"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class. Keep small for dev -- this is one of the more expensive resources in the platform if oversized."
  default     = "db.t3.micro"
}

variable "allocated_storage_gb" {
  type        = number
  description = "Allocated storage in GB."
  default     = 20
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ for high availability. Roughly doubles cost -- recommended true for prod, false for dev."
  default     = false
}

variable "backup_retention_days" {
  type        = number
  description = "Days to retain automated backups."
  default     = 7
}

variable "db_name" {
  type        = string
  description = "Name of the initial database created inside the instance."
  default     = "app"
}

variable "master_username" {
  type        = string
  description = "Master username for the database."
  default     = "app_admin"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip taking a final snapshot on destroy. Keep true for dev (fast teardown); should be false for prod."
  default     = true
}
