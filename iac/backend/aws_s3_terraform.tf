# File: ./iac/backend/aws_s3_terraform.tf

# Definição dos recursos S3 e DynamoDB (use os nomes de variáveis ou valores literais)
resource "aws_s3_bucket" "state_bucket" {
  bucket = var.terraform_state_bucket_name
  force_destroy = true 
}

resource "aws_s3_bucket_ownership_controls" "state_bucket_ownership" {
  bucket = aws_s3_bucket.state_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "state_bucket_versioning" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration { status = "Enabled" }
}
