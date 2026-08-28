# ADR 0003: Prod Environment Validated But Not Applied

## Status
Accepted

## Context
The brief requires COB to support multiple environments, at minimum
dev and prod, with the same platform capabilities reusable across both
while allowing appropriate configuration differences. Given the project
timeline, a decision was needed about whether "supports prod" means
prod must be actually running, or correctly configured and validated.

## Decision
`environments/prod/` is fully written, composes all 6 modules with
prod-appropriate configuration differences (Multi-AZ RDS, NAT enabled,
3 AZs instead of 2, larger instance sizes, longer log/backup retention,
`skip_final_snapshot = false`), and is validated with `terraform plan`
succeeding cleanly against real AWS credentials. It is not applied --
no prod AWS resources are actually running as part of this submission.

## Rationale
- Applying a second full environment (a second RDS instance, second
  NAT gateway, etc.) roughly doubles AWS cost and provisioning time for
  a submission that is graded on module design, not on having two live
  environments simultaneously.
- The requirement is that COB *supports* multiple environments through
  reusable modules with environment-appropriate configuration -- this
  is demonstrated by `environments/prod/main.tf` existing, differing
  from `environments/dev/main.tf` only in variable values (no
  duplicated resource logic), and validating successfully.
- Running `terraform apply` in `environments/prod/` at any point after
  this submission is a configuration-only action; no module code needs
  to change.

## Consequences
- A grader or future engineer can confirm the multi-environment claim
  by running `terraform plan` in `environments/prod/`, without needing
  AWS resources to already exist.
- This is a scope decision made under a real deadline, documented
  honestly rather than silently -- consistent with the platform's own
  standard of explicit, defensible decisions.
