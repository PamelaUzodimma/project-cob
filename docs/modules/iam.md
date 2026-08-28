# Identity & Access (IAM)

`modules/iam`

## What it provides
An IAM role with a correctly-shaped trust policy for the AWS service
that needs it, plus a permissions policy built from an explicit list
of scoped action+resource statements.

## Why this is a real abstraction
The module makes least-privilege access the path of least resistance:
there is no way to grant broad access without deliberately typing a
wildcard into a statement. A caller must name specific actions and
specific resource ARNs -- there's no "paste a policy" shortcut that
defaults to `"Resource": "*"`.

## Inputs
| Name | Type | Default | Description |
|---|---|---|---|
| `project` | string | — | Project/platform name |
| `environment` | string | — | `dev` or `prod` |
| `owner_team` | string | — | Owning team, used for tagging |
| `role_purpose` | string | — | Specific purpose, e.g. `ecs-task-web-app` |
| `assume_service` | string | — | AWS service principal allowed to assume the role |
| `permission_statements` | list(object) | `[]` | Scoped action+resource statements |
| `attach_managed_policy_arns` | list(string) | `[]` | Optional AWS-managed policies to attach |

## Outputs
| Name | Description |
|---|---|
| `role_arn` | ARN of the created role |
| `role_name` | Name of the created role |

## Security considerations
- Prefer `permission_statements` over `attach_managed_policy_arns` for
  anything custom; managed policies are reserved for well-known
  AWS-maintained baselines.
- Each statement requires an explicit `sid`, forcing a named,
  auditable reason for every grant.

## Known limitations
- Does not currently support resource-based policies (e.g. S3 bucket
  policies granting cross-account access) -- this module is scoped to
  identity-based policies only.
