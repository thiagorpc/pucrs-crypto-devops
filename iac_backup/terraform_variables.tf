# ============================
# File: ./iac/flow/variables.tf
# ============================

# Nome do projeto
variable "project_name" {
  type    = string
  default = "pucrs-crypto"
}

# Região da AWS
variable "aws_region" {
  description = "A região da AWS onde a infraestrutura será implantada. Exemplo: us-east-1, us-west-2"
  type        = string
  default     = "us-east-1"
}

# Porta do container
variable "container_port" {
  description = "Porta do container onde a aplicação está escutando."
  type        = string
  default     = 3000
}