# DNS do Application Load Balancer
output "alb_dns_name" {
  value       = aws_lb.crypto_alb.dns_name
  description = "Endereço DNS público do ALB para acessar a API"
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

# Security Group utilizado pelo ECS e ALB
output "ecs_security_group_id" {
  value       = aws_security_group.ecs_sg.id
  description = "ID do Security Group utilizado pelo ECS e ALB"
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
  value       = "http://${aws_s3_bucket.crypto_ui.bucket}.s3-website-${var.aws_region}.amazonaws.com"
  description = "URL pública do front-end React"
}

# Nome do bucket S3 para o front-end React
output "ui_bucket_name" {
  description = "Nome do bucket S3 para o front-end React"
  value       = aws_s3_bucket.crypto_ui.bucket
}

