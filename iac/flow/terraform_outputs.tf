

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
  description = "Nome do bucket S3 para o front-end React"
  value       = aws_s3_bucket.crypto_ui.bucket
}

# Nome do bucket S3 para Imagens
output "images_bucket_name" {
  description = "Nome do bucket S3 para armazenar imagens da API"
  value       = aws_s3_bucket.crypto_images.bucket
}

