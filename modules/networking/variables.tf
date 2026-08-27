# variables.tf
#
# BEGINNER NOTE:
# These are the ONLY knobs a consuming team can turn. Everything else
# (how many route tables, how subnets are laid out, tagging) is decided
# BY the module — that's what makes this a real abstraction instead of
# a thin wrapper around aws_vpc.

variable "project" {
  description = "Short project/platform name, used in resource naming (e.g. 'cob', 'payments')."
  type        = string
}

variable "environment" {
  description = "Environment name: dev or prod. Used in naming and tagging."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "owner_team" {
  description = "Team that owns this network, used for tagging/cost attribution."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC, e.g. 10.0.0.0/16."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across (2 is the sane minimum for anything resembling HA)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway so private subnets can reach the internet outbound. Costs ~$32/mo per NAT GW — you may want this false in dev to save cost."
  type        = bool
  default     = true
}
