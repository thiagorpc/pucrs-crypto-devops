# ============================
# File: ./iac/versions.tf (Simplificado)
# ============================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # REMOVIDO: O bloco 'backend' foi movido para a linha de comando (init)
  #          para que possamos gerenciar o S3/DynamoDB como recursos.
}

provider "aws" {
  region = var.aws_region
}