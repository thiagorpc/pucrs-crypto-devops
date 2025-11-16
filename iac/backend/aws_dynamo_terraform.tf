# ============================
# File: ./iac/backend/aws_dynamo_terraform.tf
# ============================

# DynamoDB Table para controlar locks do Terraform
# Garante que multiplos applies simultâneos não corrompam o estado
resource "aws_dynamodb_table" "lock_table" {
  name         = "${var.project_name}-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"  # Pagamento por demanda (sem precisar definir capacidade)
  hash_key     = "LockID"            # Chave primaria da tabela

  attribute {
    name = "LockID"
    type = "S"  # Tipo String
  }
}

