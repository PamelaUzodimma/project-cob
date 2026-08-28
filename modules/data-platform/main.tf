# main.tf — Data Platform Services capability (Glue + Athena)
#
# WHAT THIS GIVES A CONSUMING TEAM:
#   - A Glue Data Catalog database (namespace for tables)
#   - An optional Glue Crawler, correctly scoped (IAM role + S3 perms
#     limited to just this dataset's prefix, not the whole bucket)
#   - An Athena workgroup with its own results location and a
#     bytes-scanned cost guardrail -- not Athena's shared default
#     workgroup, which has no cost control at all
#   - Consistent naming/tagging
#
# A team calling this does NOT need to hand-write a crawler IAM policy
# (a common source of over-broad "s3:*" grants) or remember that Athena
# needs somewhere to put query results -- both handled here.

locals {
  name_prefix = "${var.project}-${var.environment}-${var.dataset_name}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner_team
    ManagedBy   = "terraform"
    Platform    = "cob"
    Dataset     = var.dataset_name
  }

  s3_target_path = "s3://${var.source_bucket_name}/${var.source_prefix}"
}

resource "aws_glue_catalog_database" "this" {
  name = replace("${local.name_prefix}-db", "-", "_") # Glue DB names conventionally use underscores

  description = "Glue catalog database for ${var.dataset_name} (${var.environment})"
}

# --- CRAWLER (optional) ---

data "aws_iam_policy_document" "crawler_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "crawler" {
  count              = var.enable_crawler ? 1 : 0
  name               = "${local.name_prefix}-crawler-role"
  assume_role_policy = data.aws_iam_policy_document.crawler_trust.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "crawler_service_role" {
  count      = var.enable_crawler ? 1 : 0
  role       = aws_iam_role.crawler[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Scoped explicitly to this dataset's prefix -- NOT the whole bucket.
# This is the least-privilege pattern again, applied to a crawler.
data "aws_iam_policy_document" "crawler_s3_access" {
  count = var.enable_crawler ? 1 : 0

  statement {
    sid       = "ListBucketScopedToPrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.source_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.source_prefix}*"]
    }
  }

  statement {
    sid       = "ReadObjectsInPrefix"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.source_bucket_arn}/${var.source_prefix}*"]
  }
}

resource "aws_iam_policy" "crawler_s3_access" {
  count  = var.enable_crawler ? 1 : 0
  name   = "${local.name_prefix}-crawler-s3-access"
  policy = data.aws_iam_policy_document.crawler_s3_access[0].json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "crawler_s3_access" {
  count      = var.enable_crawler ? 1 : 0
  role       = aws_iam_role.crawler[0].name
  policy_arn = aws_iam_policy.crawler_s3_access[0].arn
}

resource "aws_glue_crawler" "this" {
  count         = var.enable_crawler ? 1 : 0
  name          = "${local.name_prefix}-crawler"
  role          = aws_iam_role.crawler[0].arn
  database_name = aws_glue_catalog_database.this.name
  schedule      = var.crawler_schedule # null = on-demand only

  s3_target {
    path = local.s3_target_path
  }

  tags = local.common_tags
}

# --- ATHENA ---

# Athena needs somewhere to write query results -- a small, dedicated
# bucket, separate from the source data bucket (never mix data and
# query-output buckets; keeps lifecycle/cost policies independent).
resource "random_id" "athena_results_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "athena_results" {
  bucket = "${local.name_prefix}-athena-results-${random_id.athena_results_suffix.hex}"

  tags = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket                  = aws_s3_bucket.athena_results.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    id     = "expire-query-results"
    status = "Enabled"

    filter {}

    expiration {
      days = 30 # query results are disposable -- no reason to keep them long
    }
  }
}

resource "aws_athena_workgroup" "this" {
  name = "${local.name_prefix}-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    bytes_scanned_cutoff_per_query     = var.athena_bytes_scanned_cutoff_per_query

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.id}/"
    }
  }

  tags = local.common_tags
}
