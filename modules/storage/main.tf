# main.tf — Object Storage capability
#
# WHAT THIS GIVES A CONSUMING TEAM (vs. a bare aws_s3_bucket):
#   - Encryption at rest, enforced (AES256)
#   - Versioning, on by default (opt-out, not opt-in)
#   - Public access fully blocked -- the "secure by default" the brief asks for
#   - TLS-only bucket policy -- rejects any unencrypted-in-transit request
#   - Lifecycle rules for cost control (IA transition + old-version expiry)
#   - Consistent naming/tagging
#
# A team using this module cannot end up with the "some buckets have
# versioning enabled while others do not" inconsistency the brief
# describes as the current problem -- the module decides that, the
# team just says yes/no via one variable.

locals {
  name_prefix = "${var.project}-${var.environment}-${var.bucket_purpose}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner_team
    ManagedBy   = "terraform"
    Platform    = "cob"
    Purpose     = var.bucket_purpose
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "this" {
  bucket = "${local.name_prefix}-${random_id.suffix.hex}"

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "tls_only" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "tls_only" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.tls_only.json
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "cost-management"
    status = "Enabled"

    filter {}

    dynamic "transition" {
      for_each = var.transition_to_ia_days > 0 ? [1] : []
      content {
        days          = var.transition_to_ia_days
        storage_class = "STANDARD_IA"
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = var.enable_versioning ? [1] : []
      content {
        noncurrent_days = var.noncurrent_version_expiration_days
      }
    }
  }
}
