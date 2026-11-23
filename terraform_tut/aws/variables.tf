variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "aws_iam_policy_name" {
    description = "IAM policy name"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "iam_user_name" {
  description = "IAM username"
  type        = string
}

variable "snowflake_role" {
    description = "Snowflake role for the Data Engineering project"
}