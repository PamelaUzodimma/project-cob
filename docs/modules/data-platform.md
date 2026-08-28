# Data Platform Services (Glue + Athena)

`modules/data-platform`

## What it provides
A Glue Data Catalog database, an optional Glue Crawler scoped to a
specific S3 prefix (not the whole bucket), and an Athena workgroup with
its own results bucket and a per-query cost guardrail.

## Why this is a real abstraction
This module does not create its own S3 bucket -- it takes an existing
bucket (typically from `modules/storage`) as input, since the premise
of "data platform services" is making already-existing S3 data
queryable, not storing new data. The crawler's IAM policy is scoped
with an explicit `s3:prefix` condition, so it can only see the
specific dataset it's meant to catalog -- not the entire bucket,
which is a common over-permissioning mistake when this is hand-rolled.

## Inputs
| Name | Type | Default | Description |
|---|---|---|---|
| `project` / `environment` / `owner_team` | string | — | Standard naming/tagging inputs |
| `dataset_name` | string | — | Specific dataset name, e.g. `orders` |
| `source_bucket_name` / `source_bucket_arn` | string | — | Typically from `modules/storage` outputs |
| `source_prefix` | string | `""` | Folder path within the bucket for this dataset |
| `enable_crawler` | bool | `true` | Whether to create a Glue Crawler for auto schema discovery |
| `crawler_schedule` | string | `null` | Cron schedule; `null` means on-demand only |
| `athena_bytes_scanned_cutoff_per_query` | number | `1073741824` (1 GB) | Per-query cost guardrail |

## Outputs
| Name | Description |
|---|---|
| `glue_database_name` | Glue catalog database name |
| `crawler_name` | Glue crawler name (null if `enable_crawler = false`) |
| `athena_workgroup_name` | Athena workgroup name -- analysts should query using this, not `primary` |
| `athena_results_bucket` | S3 bucket where Athena writes query results |

## Security considerations
- Crawler IAM permissions are scoped to `source_prefix` only via an
  explicit `s3:prefix` condition -- not the entire source bucket.
- Athena query results are written to a dedicated, non-public bucket,
  separate from the source data bucket, with a 30-day expiration
  lifecycle rule (results are disposable).
- The Athena workgroup enforces its configuration
  (`enforce_workgroup_configuration = true`), meaning analysts cannot
  override the cost guardrail per-query.

## Known limitations
- Does not create Glue Tables directly -- relies on the crawler for
  schema discovery, or manual table definition outside Terraform, if
  `enable_crawler = false`.
- Does not configure Lake Formation permissions -- access control is
  via IAM only in this version.
