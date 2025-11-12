terraform {
  backend "s3" {
    bucket         = "${var.project_name}-github-action-tfstate-unique"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "${var.project_name}-terraform-lock"
  }
}
