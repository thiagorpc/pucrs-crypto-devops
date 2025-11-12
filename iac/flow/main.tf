terraform {
  backend "s3" {
    bucket         = "pucrs-crypto-github-action-tfstate-unique"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "pucrs-crypto-terraform-lock"
  }
}
