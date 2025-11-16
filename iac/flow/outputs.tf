# ============================
# File: ./iac/flow/outputs.tf
# ============================

# ============================
# 🌐 REDE / LOAD BALANCER / VPC
# ============================

output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.vpc.id
}

output "public_subnets_ids" {
  description = "Lista de IDs das subnets publicas"
  value       = aws_subnet.public_subnets[*].id
}

output "nlb_dns_name" {
  description = "DNS publico do Network Load Balancer (NLB)"
  value       = aws_lb.api_nlb.dns_name
}

# ============================
# ⚙️ ECS / SEGURANÇA
# ============================

output "ecs_security_group_id" {
  description = "ID do Security Group utilizado pelas Tasks ECS (recebe trafego da VPC/NLB)"
  value       = aws_security_group.ecs_sg.id
}

output "ecs_cluster_id" {
  description = "ID do ECS Cluster"
  value       = aws_ecs_cluster.cluster.id
}

# ============================
# 🧱 ECR / CONTAINERS
# ============================

output "ecr_repository_url" {
  description = "URL do repositório ECR para armazenar imagens Docker"
  value       = aws_ecr_repository.image_repo.repository_url
}

# ============================
# 🪣 ARMAZENAMENTO (S3 / DYNAMODB)
# ============================

output "ui_bucket_name" {
  description = "Nome do bucket S3 onde o front-end React esta hospedado"
  value       = aws_s3_bucket.frontend.bucket
}

output "react_ui_url" {
  description = "URL publica do front-end React hospedado no S3 via CloudFront"
  value       = aws_cloudfront_distribution.frontend_cdn.domain_name 
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

output "api_gateway_invoke_url" {
  description = "URL publica de invocação da API via API Gateway (Stage /prod)"
  value       = aws_api_gateway_stage.prod_stage.invoke_url
}

# ============================
# 🧭 META
# ============================

output "aws_region" {
  description = "Região AWS onde os recursos estão sendo criados"
  value       = var.aws_region
}

# ============================
# ☁️ CloudFront
# ============================

output "cloudfront_url_domain" {
  description = "Domain name da distribuição CloudFront para acesso HTTPS"
  value       = aws_cloudfront_distribution.frontend_cdn.domain_name 
}

output "cloudfront_distribution_id" {
  description = "ID da distribuição CloudFront"
  value       = aws_cloudfront_distribution.frontend_cdn.id
}

output "cloudfront_distribution_arn" {
  description = "ARN da distribuição CloudFront"
  value       = aws_cloudfront_distribution.frontend_cdn.arn
}

