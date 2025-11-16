# ============================
# File: ./iac/backend/aws_s3_terraform.tf
# ============================

# S3 Bucket para armazenar o estado do Terraform (terraform.tfstate)
resource "aws_s3_bucket" "state_bucket" {
  bucket        = "${var.project_name}-github-action-tfstate-unique"
  force_destroy = true  # Permite destruir o bucket mesmo que contenha objetos
}

# Controle de propriedade do bucket S3 (enforce BucketOwner)
resource "aws_s3_bucket_ownership_controls" "state_bucket_ownership" {
  bucket = aws_s3_bucket.state_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Habilita versionamento no bucket S3 para rastrear alterações no estado
resource "aws_s3_bucket_versioning" "state_bucket_versioning" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

