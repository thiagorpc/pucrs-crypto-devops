# ============================
# File: ./iac/flow/local.tf
# ============================

locals {
  encryption_secret_arn = var.secrets_encryption_key != "" ? var.secrets_encryption_key : data.aws_secretsmanager_secret.encryption_key.arn
}