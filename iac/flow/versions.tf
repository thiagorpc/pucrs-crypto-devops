# ============================
# File: ./iac/flow/versions.tf
# ============================

terraform {
  # Versão mínima do Terraform requerida para este projeto
  required_version = ">= 1.5.0"

  # ============================
  # Providers utilizados
  # ============================
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Compatível com a versão 5.x do provider AWS
    }
  }
}

