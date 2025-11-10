terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ==================================
  # BACKEND (State Locking)
  # ==================================
  backend "s3" {
    bucket         = "aws-s3-crypto-github-action-tfstate-unique"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table-crypto" # ❗️ Requer criação manual
  }
}

provider "aws" {
  region = var.aws_region
}