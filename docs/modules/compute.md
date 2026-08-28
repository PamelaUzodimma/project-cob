# Compute (ECS/Fargate)

`modules/compute-ecs`

## What it provides
An ECS cluster, Fargate task definition, running service, execution
role, CloudWatch log group, and a security group scoped to just the
container's port.

## Why this is a real abstraction
A team consuming this module doesn't need to know the difference
between an execution role and a task role, that Fargate requires
`awsvpc` network mode, how to wire a log driver, or that forgetting a
log group means silently losing all container output. All of that is
encoded once, here.

This module takes networking (`vpc_id`, `subnet_ids`) and IAM
(`task_role_arn`) as **inputs** rather than creating its own -- it
composes existing capabilities instead of duplicating them, per the
brief's requirement that compute "make sensible networking and IAM
configurations available to workloads" rather than reinventing them.

## Inputs
| Name | Type | Default | Description |
|---|---|---|---|
| `project` / `environment` / `owner_team` | string | — | Standard naming/tagging inputs |
| `service_name` | string | — | Specific service name, e.g. `web-app` |
| `vpc_id` | string | — | Typically `module.networking.vpc_id` |
| `subnet_ids` | list(string) | — | Typically `module.networking.private_subnet_ids` |
| `container_image` | string | — | Full image URI |
| `container_port` | number | `8080` | Port the container listens on |
| `cpu` / `memory` | number | `256` / `512` | Fargate task sizing |
| `desired_count` | number | `1` | Number of task copies |
| `task_role_arn` | string | `null` | Application's own IAM role, typically from `modules/iam` |
| `ingress_cidr_blocks` | list(string) | `[]` | CIDRs allowed to reach the container port |
| `log_retention_days` | number | `30` | CloudWatch log retention |

## Outputs
| Name | Description |
|---|---|
| `cluster_id` | ECS cluster ID |
| `service_name` | ECS service name |
| `task_definition_arn` | Task definition ARN |
| `security_group_id` | Service's security group ID -- consumed by e.g. `database-rds`'s `allowed_security_group_ids` |
| `log_group_name` | CloudWatch log group name |

## Security considerations
- Tasks run with `assign_public_ip = false` -- always in private
  subnets, never directly internet-facing.
- Execution role (image pull, log write) and task role (application
  permissions) are deliberately separate -- see ADR 0001.

## Known limitations
- No load balancer is provisioned; the service is reachable only
  within the VPC. Adding an ALB is a natural next module.
- EC2-based compute (as opposed to Fargate) is not implemented in this
  version -- documented as a known gap, not silently omitted.
