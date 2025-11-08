# Define a região da AWS
variable "aws_region" {
  description = "A região da AWS onde a infraestrutura será implantada."
  type        = string
  default     = "us-east-1" # Região padrão, pode ser alterada via arquivo .tfvars
}