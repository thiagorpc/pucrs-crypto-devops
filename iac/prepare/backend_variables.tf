# ============================
# File: ./iac/variables.tf
# ============================

# Nome do bucket S3 para o front-end
variable "terraform_lock_dynamodb_name" {
  description = "Nome da tabela DynamoDB para controle de Lock do Terraform."
  type        = string
  default     = "pucrs-crypto-terraform-lock"
}

# Nome do Bucket S3 para o Terraform State
variable "terraform_state_bucket_name" {
  description = "Nome do bucket S3 onde o status de deploy ou update do Terraform é mantido"
  type        = string
  default     = "pucrs-crypto-github-action-tfstate-unique"
}

