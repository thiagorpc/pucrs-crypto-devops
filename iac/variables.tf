# Região da AWS
variable "aws_region" {
  description = "A região da AWS onde a infraestrutura será implantada."
  type        = string
  default     = "us-east-1"
}

# CIDR da VPC
variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Subnets públicas
variable "public_subnet_cidrs" {
  description = "Lista de CIDRs das subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Nome do serviço ECS
variable "service_name" {
  description = "Nome do serviço ECS"
  type        = string
  default     = "crypto-api"
}

# Porta do container
variable "container_port" {
  description = "Porta do container da aplicação"
  type        = number
  default     = 3000
}

# Nome do bucket S3 para o front-end
variable "react_bucket_name" {
  description = "Nome do bucket S3 para hospedar o front-end React"
  type        = string
  default     = "pucrs-crypto-frontend"
}
