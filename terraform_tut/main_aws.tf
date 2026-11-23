data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_user" "admin_user" {
  name = "opeyemi"
  tags = {
    Description = "Technical Team Lead"
  }
}

data "aws_iam_group" "existing" {
  group_name = "project-zomato-users"
}

resource "aws_iam_user_group_membership" "admin_user" {
  user   = aws_iam_user.admin_user.name
  groups = [data.aws_iam_group.existing.group_name]
}

resource "time_static" "created" {}

locals {
  created_date = formatdate("YYYYMMDD", time_static.created.rfc3339)
}

resource "aws_s3_bucket" "terraform_bucket" {
  bucket = format(
    "opeyemi-app-data-%s-%s-%s-an",
    local.created_date,
    data.aws_caller_identity.current.account_id,
    data.aws_region.current.region
  )
  bucket_namespace = "account-regional"

  tags = {
    CreatedOn   = formatdate("YYYY-MM-DD", time_static.created.rfc3339)
    Description = "My first Bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_bucket" {
  bucket                  = aws_s3_bucket.terraform_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "s3_access" {
    name = "app-s3-access-role"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# ---- 3. The access policy (what the role can do) ----
data "aws_iam_policy_document" "s3_access" {
  # Bucket-level action: listing
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.app.arn]
  }

  # Object-level actions: read, write, delete
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.app.arn}/*"]
  }
}

resource "aws_iam_policy" "s3_access" {
  name   = "app-s3-access-policy"
  policy = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.s3_access.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# ---- 4. Bucket policy (resource-based: restricts the bucket itself) ----
data "aws_iam_policy_document" "bucket" {
  statement {
    sid     = "AllowRoleAccess"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.s3_access.arn]
    }

    resources = [
      aws_s3_bucket.app.arn,
      "${aws_s3_bucket.app.arn}/*",
    ]
  }

  # Refuse any non-HTTPS request
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.app.arn,
      "${aws_s3_bucket.app.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "app" {
  bucket = aws_s3_bucket.app.id
  policy = data.aws_iam_policy_document.bucket.json

  # Public access block must exist first, or the policy apply can race it
  depends_on = [aws_s3_bucket_public_access_block.app]
}