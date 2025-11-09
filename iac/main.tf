# Define o provedor de infraestrutura (AWS)
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configura o provedor AWS
provider "aws" {
  region = var.aws_region
}

# 1. Cria o Repositório ECR (Elastic Container Registry)
# Onde as imagens Docker serão armazenadas
resource "aws_ecr_repository" "crypto_api_repo" {
  name                 = "pucrs-crypto-api-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 2. Cria o Cluster ECS
# O ambiente lógico onde o serviço Fargate irá rodar
resource "aws_ecs_cluster" "crypto_cluster" {
  name = "pucrs-crypto-cluster"
}

# Pendente Incluir:
# _ Criação da VPC,
# _ Subnets,
# _ Load Balancer
# _ Roles IAM necessárias para o Fargate.
