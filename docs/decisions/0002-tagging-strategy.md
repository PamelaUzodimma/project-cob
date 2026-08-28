# ADR 0002: Consistent Naming and Tagging via Shared Locals Pattern

## Status
Accepted

## Context
The brief identifies inconsistent naming and tagging as a symptom of
the current ad-hoc provisioning process, and asks COB to encourage
these standards through the platform rather than relying on individual
developers to remember them.

## Decision
Every module defines the same `locals` pattern:

```hcl
locals {
  name_prefix = "<project>-<environment>-<purpose>"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner_team
    ManagedBy   = "terraform"
    Platform    = "cob"
    # capability-specific tag, e.g. Purpose / Service / Dataset
  }
}
```

Every resource in every module uses `local.name_prefix` for naming and
merges `local.common_tags` into its tags. This is enforced by
convention (code review / module template), not by a Terraform
mechanism -- Terraform has no way to force tags onto resources it
doesn't own.

## Consequences
- Every resource COB creates is identifiable by project, environment,
  owner team, and platform origin -- supports cost attribution and
  "what created this and why" auditing without reading Terraform source.
- Because the pattern is copy-consistent across all 6 modules, a new
  module written by a future platform engineer has an obvious template
  to follow, satisfying the "new engineer can understand this without
  a walkthrough" requirement.
- Risk: since this isn't mechanically enforced, a future module could
  skip it. A stronger version of this decision (not implemented here,
  noted as a future improvement) would use `default_tags` at the AWS
  provider level to enforce this automatically rather than per-module.
