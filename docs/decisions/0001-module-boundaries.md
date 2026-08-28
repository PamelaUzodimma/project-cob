# ADR 0001: Module Boundaries Around Capabilities, Not Resources

## Status
Accepted

## Context
The brief explicitly warns against modules that are thin wrappers around
a single AWS resource (e.g. a module that only exposes `aws_s3_bucket`).
We needed a principle for deciding what belongs inside one module versus
being split across several.

## Decision
Each module represents one **capability** a consuming team needs --
answering "what does a team actually want to accomplish" rather than
"what AWS resource type is this." A capability typically bundles 5-10
related resources plus the security/operational configuration a team
would otherwise have to remember to add themselves.

Examples:
- `storage` doesn't just create a bucket -- it also configures
  encryption, versioning, public access blocking, a TLS-only bucket
  policy, and lifecycle rules, because a team asking for "storage"
  needs all of that to have something usable in production.
- `compute-ecs` bundles the cluster, task definition, service, execution
  role, log group, and a scoped security group, because none of those
  are independently useful -- a task definition without a cluster does
  nothing.

## Consequences
- Fewer, larger modules rather than many small ones. This trades some
  flexibility (a team can't opt out of, say, TLS enforcement on a
  bucket) for the removal of an entire class of "team forgot to
  configure X" security gaps.
- Cross-cutting concerns (networking, IAM) are still separate modules,
  because they are consumed by multiple other capabilities (compute,
  RDS, data-platform all need network placement; compute and data
  crawlers both need IAM roles) -- splitting them out avoids duplicating
  that logic inside every consumer module.
