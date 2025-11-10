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

# Security Group
output "ecs_security_group_id" {
  value       = aws_security_group.ecs_sg.id
  description = "ID do Security Group utilizado pelo ECS e ALB"
}

# VPC ID
output "vpc_id" {
  value       = aws_vpc.crypto_vpc.id
  description = "ID da VPC criada"
}

# Subnets públicas
output "public_subnets_ids" {
  value       = aws_subnet.public_subnets[*].id
  description = "Lista de IDs das subnets públicas"
}

# url para o frontend Reacr
output "react_frontend_url" {
  description = "URL pública do front-end React"
  value       = aws_s3_bucket.react_frontend.website_endpoint
}

