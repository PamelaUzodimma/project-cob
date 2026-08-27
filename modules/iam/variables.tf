# variables.tf
#
# BEGINNER NOTE: the design goal here is to make the SAFE thing the
# EASY thing. A caller can't accidentally grant "*" permissions without
# deliberately typing "*" into a statement — there's no shortcut that
# defaults to broad access, unlike hand-writing a policy document from
# scratch (where copy-pasting an example with "Resource": "*" is the
# path of least resistance).

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
  description = "Team that owns this role, used for tagging."
  type        = string
}

variable "role_purpose" {
  description = "Short, specific purpose of this role, e.g. 'ecs-task-web-app' or 'lambda-ingest'. Used in naming — be specific, not generic ('app-role' is a smell)."
  type        = string
}

variable "assume_service" {
  description = "The AWS service principal allowed to assume this role, e.g. 'ecs-tasks.amazonaws.com', 'ec2.amazonaws.com', 'rds.amazonaws.com', 'glue.amazonaws.com'."
  type        = string
}

variable "permission_statements" {
  description = <<-EOT
    List of scoped permission statements. Each statement grants specific
    actions on specific resource ARNs -- NOT a raw policy document.
    This shape forces least-privilege thinking: you must name the exact
    actions and exact resources, there's no "just paste a policy" path.

    Example:
    [
      {
        sid       = "ReadWriteAppBucket"
        actions   = ["s3:GetObject", "s3:PutObject"]
        resources = ["arn:aws:s3:::my-bucket/*"]
      }
    ]
  EOT
  type = list(object({
    sid       = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "attach_managed_policy_arns" {
  description = "Optional list of AWS-managed policy ARNs to attach (use sparingly -- prefer permission_statements for anything custom; managed policies are for well-known AWS-maintained baselines like the ECS task execution policy)."
  type        = list(string)
  default     = []
}
