# ============================
# File: ./iac/flow/main.tf
# ============================

# Configuração do Terraform Backend
# Define onde o estado remoto sera armazenado e como o locking sera gerenciado.
terraform {
  backend "s3" {
    # Bucket S3 para armazenar o estado do Terraform
    bucket         = "pucrs-crypto-github-action-tfstate-unique"

    # Nome do arquivo do estado dentro do bucket
    key            = "terraform.tfstate"

    # Região onde o bucket e a tabela DynamoDB estão localizados
    region         = "us-east-1"

    # Habilita criptografia do arquivo de estado no S3
    encrypt        = true

    # Tabela DynamoDB para controlar locks e evitar execução simultânea de `terraform apply`
    dynamodb_table = "pucrs-crypto-terraform-lock"
  }
}

