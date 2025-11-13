# ============================
# File: ./iac/flow/outputs.tf
# ============================




# ============================
# 🪣 ARMAZENAMENTO (S3 / DYNAMODB)
# ============================

output "ui_bucket_name" {
  description = "Nome do bucket S3 onde o front-end React está hospedado"
  value       = aws_s3_bucket.frontend.bucket
}

output "react_ui_url" {
  description = "URL pública do front-end React hospedado no S3"
  value       = aws_s3_bucket_website_configuration.frontend_website.website_endpoint
}

output "images_bucket_name" {
  description = "Nome do bucket S3 onde as imagens da API são armazenadas"
  value       = aws_s3_bucket.images.bucket
}

output "terraform_lock_table" {
  description = "Tabela DynamoDB usada para controle de lock do Terraform"
  value       = "${var.project_name}-terraform-lock"
}

# ============================
# 🚀 API GATEWAY
# ============================



# ============================
# 🧭 META
# ============================

output "aws_region" {
  description = "Região AWS onde os recursos estão sendo criados"
  value       = var.aws_region
}
