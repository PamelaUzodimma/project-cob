# Example: Web App with Datastore

This is a **reference example** showing how an engineering team consumes
COB to provision a realistic combination of infrastructure -- without
touching any AWS resource directly and without needing to understand
how networking, IAM, or security groups work internally.

## What this provisions

A team building a containerized web application that needs to:
- run in a private, secure network
- store files in S3
- run as an ECS Fargate service
- read/write a Postgres database
- expose analytics-ready data via Glue + Athena

...gets all of that by composing **6 module calls**, ~50 lines of
configuration total. Compare this to hand-writing the ~35+ individual
AWS resources this expands into.

## Composition graph

```
networking (VPC, subnets, routing)
    │
    ├──> iam (task role: app permissions)
    │        │
    ├──> storage (S3 bucket: encrypted, versioned, TLS-only)
    │        │
    ├──> compute-ecs (Fargate service) ──uses──> networking + iam
    │
    ├──> database-rds (Postgres) ──uses──> networking + compute-ecs's SG
    │
    └──> data-platform (Glue + Athena) ──uses──> storage's bucket
```

Every arrow is a Terraform module **output** feeding another module's
**input** -- no manually copy-pasted IDs, no hardcoded ARNs.

## Running this example

This example is self-contained but expects its own state/backend
configuration -- copy `backend.tf` from `environments/dev/` and adjust
the `key`, or run with local state for a one-off demo:

```bash
terraform init
terraform plan
terraform apply
```

## What you do NOT need to know to use this

- How VPC routing or NAT gateways work
- How to write an ECS task execution role's trust policy
- How to scope an IAM policy to a single S3 prefix
- Where Athena needs to write query results
- How to generate and securely store a database password

All of that is encoded in the modules this example calls.
