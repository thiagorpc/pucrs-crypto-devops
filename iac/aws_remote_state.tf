# ============================
# File: ./iac/remote_state.tf (Novo arquivo)
# ============================

# Recurso: S3 Bucket para o Terraform State
resource "aws_s3_bucket" "state_bucket" {
  bucket = "aws-s3-crypto-github-action-tfstate-unique"
  acl    = "private"
  
  # CRUCIAL: Permite que o 'terraform destroy' remova o bucket
  # mesmo que ainda contenha o arquivo terraform.tfstate
  force_destroy = true 

  versioning {
    enabled = true
  }
}

# Recurso: DynamoDB Lock Table para o State Locking
resource "aws_dynamodb_table" "lock_table" {
  name           = "terraform-lock-table-crypto"
  billing_mode   = "PAY_PER_REQUEST"

  # PK deve ser "LockID", como você especificou
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S" # S de String
  }
}