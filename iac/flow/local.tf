# ============================
# File: ./iac/flow/local.tf
# ============================

# Define o ARN do segredo de criptografia utilizado nas tasks ECS.
# Usa a variável `secrets_encryption_key` se fornecida, caso contrário usa o Secrets Manager.
locals {
  encryption_secret_arn = var.secrets_encryption_key != "" ? var.secrets_encryption_key : data.aws_secretsmanager_secret.encryption_key.arn
}