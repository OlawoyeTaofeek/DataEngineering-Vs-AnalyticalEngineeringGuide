provider "aws" {
  region = var.aws_region
}

resource "aws_iam_user" "data_engineer" {
    name = var.iam_user_name
    tags = {
        Description = "Analytical Engineering Lead"
    }
    force_destroy = true
}

resource "aws_iam_user" "data_engineer_2" {
    name = "habephe"
    tags = {
        Description = "Analytical Engineering Lead"
    }
    force_destroy = true
}

data "aws_iam_group" "existing_group" {
    group_name = "project-zomato-users"
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.data.arn]
  }
}

resource "aws_iam_user_group_membership" "admin-user" {
    user = aws_iam_user.data_engineer.name
    groups = [data.aws_iam_group.existing_group.group_name]
}

resource "aws_s3_bucket" "data" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

resource "aws_iam_policy" "s3_access" {
    name = "${var.iam_user_name}-s3_access"
    description = "S3 Access IAM Policy"
    policy = jsondecode(
        {
            version = "2012-10-17"
            statement = [
                {
                    Action = [
                        "s3:List*",
                    ]
                    effect = "Allow"
                    resource = aws_s3_bucket.data.arn
                },
                {
                    Effect = "Allow"

                    Action = [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject"
                    ]

                    Resource = "${aws_s3_bucket.data.arn}/*"
                }
            ]
        }
    )
}

## Assign the policy to the user
resource "aws_iam_user_policy_attachment" "data_engineer_policy" {
    user = aws_iam_user.data_engineer.name 
    policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_policy" "new_s3_access" {
  name   = "new-s3-access"
  policy = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_group" "group" {
  name = "analytical-engineer"
}

resource "aws_iam_group_membership" "engineering_team" {
    name = "data-engineers-membership"
    users = [
        aws_iam_user.data_engineer.name,
        aws_iam_user.data_engineer_2.name 
    ]
    group = aws_iam_group.group.name
}