

# Security Group utilizado pelo ECS
output "ecs_security_group_id" {
  value       = aws_security_group.ecs_sg.id
  description = "ID do Security Group utilizado pelas Tasks ECS (recebe tráfego da VPC/NLB)"
}

# ID da VPC criada
output "vpc_id" {
  value       = aws_vpc.crypto_vpc.id
  description = "ID da VPC criada"
}

# IDs das subnets públicas
output "public_subnets_ids" {
  value       = aws_subnet.public_subnets[*].id
  description = "Lista de IDs das subnets públicas"
}

# URL pública do front-end React hospedado no S3
output "react_ui_url" {
  value       = aws_s3_bucket_website_configuration.crypto_ui_website.website_endpoint
  description = "URL pública do front-end React"
}

# Nome do bucket S3 para o front-end React
output "ui_bucket_name" {
  value       = aws_s3_bucket.crypto_ui.bucket
  description = "Nome do bucket S3 para o front-end React"
}

# Nome do bucket S3 para Imagens
output "images_bucket_name" {
  value       = aws_s3_bucket.crypto_images.bucket
  description = "Nome do bucket S3 para armazenar imagens da API"
}

# ============================
# File: ./iac/flow/outputs.tf
# ============================

# DNS do Network Load Balancer (NLB)
output "nlb_dns_name" {
  value       = aws_lb.crypto_api_nlb.dns_name
  description = "Endereço DNS público do NLB para acessar a API via API Gateway"
}

# ID do ECS Cluster
output "ecs_cluster_id" {
  value       = aws_ecs_cluster.crypto_cluster.id
  description = "ID do ECS Cluster"
}

# URL do repositório ECR
output "ecr_repository_url" {
  value       = aws_ecr_repository.crypto_api_repo.repository_url
  description = "URL do repositório ECR para armazenar imagens Docker"
}

# URL do API Gateway
output "api_gateway_url" {
  value       = "${aws_api_gateway_stage.prod_stage.invoke_url}/"
  description = "URL base do API Gateway (Stage /prod)"
}

# ============================
# File: ./iac/flow/outputs.tf
# ============================

# 🌐 URL pública da API Gateway
output "api_gateway_invoke_url" {
  description = "URL pública para acessar a API via API Gateway"
  value       = "https://${aws_api_gateway_rest_api.project_api_gateway.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.prod_stage.stage_name}"
}

# 🧱 DNS do NLB (útil para integração direta, se necessário)
output "nlb_dns_name" {
  description = "DNS público do Network Load Balancer (NLB)"
  value       = aws_lb.crypto_api_nlb.dns_name
}

# 🪣 Bucket do Frontend (UI)
output "s3_bucket_ui" {
  description = "Nome do bucket S3 para o front-end React"
  value       = var.react_bucket_name
}

# 🔒 DynamoDB Table usada para lock do Terraform
output "terraform_lock_table" {
  description = "Tabela DynamoDB usada para controle de estado (lock)"
  value       = var.terraform_lock_dynamodb_name
}

# ⚙️ Região padrão da AWS
output "aws_region" {
  description = "Região onde os recursos estão sendo criados"
  value       = var.aws_region
}
