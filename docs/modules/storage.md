# Object Storage

`modules/storage`

## What it provides
An S3 bucket with encryption at rest, versioning, full public-access
blocking, a TLS-only bucket policy, and cost-conscious lifecycle rules
(transition to Standard-IA, expire old versions) -- all on by default.

## Why this is a real abstraction
This is the capability the brief specifically calls out as the test
case for "real abstraction vs. thin wrapper." A bare `aws_s3_bucket`
gives a team nothing; this module gives a team the same secure,
consistent bucket configuration every time, eliminating the
"some buckets have versioning, some don't" inconsistency described
in the brief as the current problem.

## Inputs
| Name | Type | Default | Description |
|---|---|---|---|
| `project` | string | — | Project/platform name |
| `environment` | string | — | `dev` or `prod` |
| `owner_team` | string | — | Owning team, used for tagging |
| `bucket_purpose` | string | — | Specific purpose, e.g. `app-uploads` |
| `enable_versioning` | bool | `true` | Enable object versioning |
| `noncurrent_version_expiration_days` | number | `90` | Days before old versions are deleted |
| `transition_to_ia_days` | number | `30` | Days before objects move to Standard-IA (0 to disable) |

## Outputs
| Name | Description |
|---|---|
| `bucket_id` | Bucket name/ID |
| `bucket_arn` | Bucket ARN |

## Security considerations
- Public access is fully blocked at the bucket level; there is no
  input to disable this.
- A bucket policy denies any request made without TLS
  (`aws:SecureTransport = false`).
- Bucket names include a random suffix to guarantee global uniqueness
  without requiring the caller to coordinate naming manually.

## Known limitations
- Does not support cross-region replication.
- Does not currently support customer-managed KMS keys (uses AES256
  SSE-S3) -- a future iteration could add a `kms_key_arn` input for
  teams with stricter key-management requirements.
