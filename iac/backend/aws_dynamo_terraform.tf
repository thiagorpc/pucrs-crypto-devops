# File: ./iac/backend/aws_dynamo_terraform.tf

# Recurso: DynamoDB Lock Table para o State Locking
resource "aws_dynamodb_table" "lock_table" {
  name           = "${var.project_name}-terraform-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S" # S de String
  }
}