# ============================
# File: ./iac/flow/data.tf
# ============================

data "aws_secretsmanager_secret" "encryption_key" {
  name = "pucrs-crypto-api/encryption-key"
}