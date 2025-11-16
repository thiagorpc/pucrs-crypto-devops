# ============================
# File: ./iac/flow/variables.tf
# ============================

# Nome do projeto
variable "project_name" {
  description = "Nome do projeto usado para nomeação de recursos"
  type        = string
  default     = "pucrs-crypto"
}

# Ambiente do projeto (NODE_ENV)
variable "project_stage" {
  description = "Ambiente do projeto (ex: development, staging, production)"
  type        = string
  default     = "production"
}

# Região da AWS
variable "aws_region" {
  description = "Região AWS onde a infraestrutura sera criada. Ex: us-east-1"
  type        = string
  default     = "us-east-1"
}

# CIDR da VPC
variable "vpc_cidr" {
  description = "CIDR da VPC. Exemplo: 10.0.0.0/16"
  type        = string
  default     = "10.0.0.0/16"
}

# Lista de subnets publicas
variable "public_subnet_cidrs" {
  description = "Lista de CIDRs para subnets publicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Lista de subnets privadas
variable "private_subnet_cidrs" {
  description = "Lista de CIDRs para subnets privadas"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

# Host do container
variable "container_host" {
  description = "Endereço IP onde o container esta escutando"
  type        = string
  default     = "0.0.0.0"
}

# Porta do container
variable "container_port" {
  description = "Porta em que o container esta escutando"
  type        = number
  default     = 3000
}

# Time Zone do container
variable "container_TZ" {
  description = "TimeZone configurado no container"
  type        = string
  default     = "America/Sao_Paulo"
}

# ============================
# ECS (Fargate)
# ============================

# CPU da Task ECS
variable "ecs_cpu" {
  description = "Quantidade de CPU alocada para a task ECS Fargate. Exemplo: '256' (0.25 vCPU)"
  type        = string
  default     = "256"
}

# Memória da Task ECS
variable "ecs_memory" {
  description = "Quantidade de memória RAM alocada para a task ECS Fargate. Exemplo: '512' (512MB)"
  type        = string
  default     = "512"
}

# Tag da imagem Docker
variable "image_tag" {
  description = "Tag da imagem Docker utilizada pelo ECS"
  type        = string
  default     = "latest"
}

# ARN da chave de criptografia no Secrets Manager (opcional)
variable "secrets_encryption_key" {
  description = "ARN da chave de criptografia no AWS Secrets Manager. Se vazio, sera usado o padrão."
  type        = string
  default     = ""
}

