# variables.tf
#
# BEGINNER NOTE: notice how few knobs this exposes compared to how many
# resources main.tf will create. That gap IS the abstraction -- the
# module makes ~6 decisions (encryption algorithm, versioning, public
# access blocking, TLS enforcement, lifecycle defaults, naming/tagging)
# so the consumer only has to make ~4 (purpose, environment, whether
# they need versioning, how long to keep old versions).

variable "project" {
  description = "Short project/platform name, used in resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name: dev or prod."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "owner_team" {
  description = "Team that owns this bucket, used for tagging."
  type        = string
}

variable "bucket_purpose" {
  description = "Short, specific purpose of this bucket, e.g. 'app-uploads', 'data-lake-raw'. Used in naming."
  type        = string
}

variable "enable_versioning" {
  description = "Enable S3 object versioning -- protects against accidental overwrite/delete. Recommended true for anything holding data you can't easily regenerate."
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Days to keep old (noncurrent) object versions before permanently deleting them. Controls storage cost growth from versioning. Set higher for compliance-sensitive data."
  type        = number
  default     = 90
}

variable "transition_to_ia_days" {
  description = "Days before objects transition to S3 Standard-IA (cheaper storage class for infrequently accessed data). Set to 0 to disable."
  type        = number
  default     = 30
}
