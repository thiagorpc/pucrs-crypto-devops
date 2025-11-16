# ============================
# File: ./iac/flow/local.tf
# ============================

# Define o ARN do segredo de criptografia utilizado nas tasks ECS.
# Usa a variavel `secrets_encryption_key` se fornecida, caso contrario usa o Secrets Manager.
locals {
  encryption_secret_arn = var.secrets_encryption_key != "" ? var.secrets_encryption_key : data.aws_secretsmanager_secret.encryption_key.arn
}
