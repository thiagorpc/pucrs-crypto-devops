# ============================
# File: ./iac/flow/provider.tf
# ============================

# Configuração do provider AWS
# Define a região padrão onde os recursos serão criados
provider "aws" {
  region = var.aws_region
}
