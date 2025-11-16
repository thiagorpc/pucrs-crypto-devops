# ============================
# File: ./iac/flow/data.tf
# ============================

# Recupera o segredo de criptografia do Secrets Manager
data "aws_secretsmanager_secret" "encryption_key" {
  name = "pucrs-crypto-api/encryption-key"
}
