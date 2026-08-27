# main.tf — Identity & Access capability
#
# WHAT THIS GIVES A CONSUMING TEAM:
#   - An IAM role with a correctly-shaped trust policy for the service
#     that needs it (they don't hand-write assume-role JSON)
#   - A single scoped permissions policy built FROM a list of specific
#     actions+resources (they can't accidentally grant "*")
#   - Consistent naming/tagging so security can audit "which roles exist
#     and why" without reading Terraform source
#
# This is the least-privilege ENCOURAGEMENT the brief asks for: the
# module doesn't prevent someone from writing "*" into permission_statements,
# but it makes the deliberate, narrow path the default path.

locals {
  name_prefix = "${var.project}-${var.environment}-${var.role_purpose}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner_team
    ManagedBy   = "terraform"
    Platform    = "cob"
    Purpose     = var.role_purpose
  }

  has_custom_statements = length(var.permission_statements) > 0
}

# Trust policy: WHO can assume this role.
data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.assume_service]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${local.name_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = local.common_tags
}

# Permission policy: WHAT the role can do, built from the caller's
# scoped statement list -- never a hand-authored blob.
data "aws_iam_policy_document" "permissions" {
  count = local.has_custom_statements ? 1 : 0

  dynamic "statement" {
    for_each = var.permission_statements
    content {
      sid       = statement.value.sid
      effect    = "Allow"
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_policy" "this" {
  count  = local.has_custom_statements ? 1 : 0
  name   = "${local.name_prefix}-policy"
  policy = data.aws_iam_policy_document.permissions[0].json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "custom" {
  count      = local.has_custom_statements ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[0].arn
}

# Optional AWS-managed policies (e.g. ECS task execution baseline)
resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.attach_managed_policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.value
}
