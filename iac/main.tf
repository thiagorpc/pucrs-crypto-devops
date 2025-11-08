# Define o provedor de infraestrutura (AWS)
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use uma versão recente e estável
    }
  }
}

# Configura o provedor AWS (a região será definida via variável)
provider "aws" {
  region = var.aws_region
}