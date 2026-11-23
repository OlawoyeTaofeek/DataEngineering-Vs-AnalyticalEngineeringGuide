data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_user" "admin-user" {
    name = "opeyemi"
    tags = {
        Description = "Technical Team Lead"
    }
}

data "aws_iam_group" "existing" {
    group_name = "project-zomato-users"
}

resource "aws_iam_user_group_membership" "admin-user" {
    user = aws_iam_user.admin-user.name
    groups = [data.aws_iam_group.existing.group_name]
}


resource "aws_s3" "name" {
  
}