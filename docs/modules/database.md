# Relational Database (RDS)

`modules/database-rds`

## What it provides
An RDS instance with a correctly-scoped DB subnet group, a security
group restricted to explicitly named source security groups,
encryption at rest, and an auto-generated password stored in AWS
Secrets Manager.

## Why this is a real abstraction
Notably: **there is no password input**. See
[ADR 0004](../decisions/0004-rds-credential-handling.md) for the full
reasoning -- in short, this eliminates an entire class of "plaintext
secret committed to git" mistakes by design, not by policy.

## Inputs
| Name | Type | Default | Description |
|---|---|---|---|
| `project` / `environment` / `owner_team` | string | — | Standard naming/tagging inputs |
| `db_purpose` | string | — | Specific purpose, e.g. `orders` |
| `vpc_id` | string | — | Typically `module.networking.vpc_id` |
| `private_subnet_ids` | list(string) | — | Typically `module.networking.private_subnet_ids` |
| `allowed_security_group_ids` | list(string) | `[]` | Security groups allowed to connect (e.g. an ECS service's SG) |
| `engine` | string | `postgres` | `postgres` or `mysql` |
| `engine_version` | string | `16.4` | Engine version |
| `instance_class` | string | `db.t3.micro` | RDS instance size |
| `allocated_storage_gb` | number | `20` | Storage size |
| `multi_az` | bool | `false` | High availability -- roughly doubles cost |
| `backup_retention_days` | number | `7` | Automated backup retention |
| `db_name` | string | `app` | Initial database name |
| `master_username` | string | `app_admin` | Master username |
| `skip_final_snapshot` | bool | `true` | Skip final snapshot on destroy (should be `false` for prod) |

## Outputs
| Name | Description |
|---|---|
| `db_instance_id` | RDS instance ID |
| `db_endpoint` | Connection endpoint (host:port) |
| `secret_arn` | Secrets Manager ARN holding credentials -- applications read from here |
| `security_group_id` | Database's security group ID |

## Security considerations
- Always placed in private subnets -- never public.
- Access is granted per named security group (`allowed_security_group_ids`),
  not CIDR ranges, wherever possible.
- Storage is encrypted at rest by default, with no way to disable it.
- Password lives only in Secrets Manager and Terraform state (see ADR 0004).

## Known limitations
- Does not support read replicas in this version.
- `engine_version` is a single string input -- no automated minor-version
  upgrade policy is configured.
