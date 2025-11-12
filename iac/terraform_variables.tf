# ============================
# File: ./iac/variables.tf
# ============================

# Região da AWS
variable "aws_region" {
  description = "A região da AWS onde a infraestrutura será implantada. Exemplo: us-east-1, us-west-2"
  type        = string
  default     = "us-east-1"
}

# CIDR da VPC
variable "vpc_cidr" {
  description = "CIDR da VPC. Exemplo: 10.0.0.0/16"
  type        = string
  default     = "10.0.0.0/16"
}

# Subnets públicas
variable "public_subnet_cidrs" {
  description = "Lista de CIDRs das subnets públicas para o projeto."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Nome do serviço ECS
variable "service_name" {
  description = "Nome do serviço ECS que será executado no Fargate."
  type        = string
  default     = "crypto-api"
}

# Porta do container
variable "container_port" {
  description = "Porta do container onde a aplicação está escutando."
  type        = string
  default     = 3000
}

# Nome do bucket S3 para o front-end
variable "react_bucket_name" {
  description = "Nome do bucket S3 onde o front-end React será hospedado."
  type        = string
  default     = "pucrs-crypto-ui"
}

# Tamanho da instância ECS Fargate (CPU)
variable "ecs_cpu" {
  description = "Quantidade de CPU alocada para a task ECS Fargate. Exemplo: '256' (0.25 vCPU)"
  type        = string
  default     = "256"
}

# Tamanho da memória ECS Fargate (RAM)
variable "ecs_memory" {
  description = "Quantidade de memória (RAM) alocada para a task ECS Fargate. Exemplo: '512' (512MB)"
  type        = string
  default     = "512"
}

# Nome do Bucket S3 para armazenar as imagens (da API)
variable "image_bucket_name" {
  description = "Nome do bucket S3 onde as imagens da aplicação serão armazenadas"
  type        = string
  default     = "crypto-api-images"
}

# Tag da imagem Docker
# Utilizado pelo FARGATE para ele reconhecer a nova versão e colocar em produção
variable "image_tag" {
  description = "TAG imagem Docker para o projeto crypto"
  type        = string
  default     = "latest" 
}

# AWS Secrets encryption key
variable "secrets_encryption_key" {
  description = "Variavel Encription KEY na AWS."
  type        = string
  default     = "arn:aws:secretsmanager:us-east-1:202533542500:secret:crypto-api/encryption-key-kGeYT2*"
}
