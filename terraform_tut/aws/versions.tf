terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.20"
    }
  }

  # Remote state with native S3 locking (Terraform >= 1.10). Create the state
  # bucket once by hand, then uncomment and `terraform init -migrate-state`.
  # backend "s3" {
  #   bucket       = "zomato-intelligence-tfstate-<your-account-id>"
  #   key          = "envs/dev/terraform.tfstate"
  #   region       = "eu-west-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}
