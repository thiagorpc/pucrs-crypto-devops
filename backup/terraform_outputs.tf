# ============================
# File: ./iac/outputs.tf
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