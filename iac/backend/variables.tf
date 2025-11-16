# ============================
# File: ./iac/variables.tf
# ============================

# Nome do projeto, usado para prefixos de recursos, nomes de buckets, tags, etc.
variable "project_name" {
  type    = string
  default = "pucrs-crypto"
}
