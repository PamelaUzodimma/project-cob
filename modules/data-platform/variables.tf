# variables.tf
#
# BEGINNER NOTE: this module does NOT create an S3 bucket -- it takes
# one as input (source_bucket_arn / source_bucket_name), typically
# built via the storage module. The premise of "data platform services"
# is that data already exists in S3; this module's job is to make that
# data QUERYABLE, not to store it.

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
  description = "Team that owns this data catalog, used for tagging."
}

variable "dataset_name" {
  type        = string
  description = "Short, specific name for this dataset/domain, e.g. 'orders', 'clickstream'. Used in naming the Glue database."
}

variable "source_bucket_name" {
  type        = string
  description = "Name of the S3 bucket containing the data -- typically module.storage_demo.bucket_id from the calling environment."
}

variable "source_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket containing the data -- typically module.storage_demo.bucket_arn."
}

variable "source_prefix" {
  type        = string
  description = "Prefix (folder path) within the bucket that holds this dataset, e.g. 'raw/orders/'. Scopes crawler and query permissions to just this data, not the whole bucket."
  default     = ""
}

variable "enable_crawler" {
  type        = bool
  description = "Whether to create a Glue Crawler to auto-discover schema. If false, you're expected to define tables manually (e.g. via a future Terraform table resource, or manually in the console)."
  default     = true
}

variable "crawler_schedule" {
  type        = string
  description = "Cron expression for how often the crawler runs, e.g. 'cron(0 6 * * ? *)' for daily at 6am UTC. Null means on-demand only (no schedule) -- a reasonable, cost-conscious default."
  default     = null
}

variable "athena_bytes_scanned_cutoff_per_query" {
  type        = number
  description = "Cost control: max bytes a single Athena query is allowed to scan before Athena kills it. Default 1GB -- deliberately conservative; raise explicitly for larger legitimate queries. This exists because a bad SELECT * can otherwise scan (and bill) an entire dataset."
  default     = 1073741824 # 1 GB
}
