# ============================
# File: ./iac/s3.tf
# ============================

# ============================
# S3 para Frontend React (UI)
# ============================
resource "aws_s3_bucket" "crypto_ui" {
 bucket = var.react_bucket_name # 🔄 Usando variável
 tags = { Name = "crypto-ui-bucket" }

 force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "crypto_ui_ownership" {
 bucket = aws_s3_bucket.crypto_ui.id
 rule {
 object_ownership = "BucketOwnerEnforced"
 }
}

# 🎯 CORREÇÃO: Desativar 'BlockPublicPolicy' para permitir a política de acesso público
resource "aws_s3_bucket_public_access_block" "crypto_ui_public_access_block" {
 bucket = aws_s3_bucket.crypto_ui.id

 # NECESSÁRIO: Permite que a política pública (abaixo) seja aplicada.
 block_public_policy = false 
 
 # Manter as outras restrições
 block_public_acls = true
 ignore_public_acls = true
 restrict_public_buckets = false 
}


resource "aws_s3_bucket_website_configuration" "crypto_ui_website" {
 bucket = aws_s3_bucket.crypto_ui.id
 index_document {
 suffix = "index.html"
 }
 # Usar index.html para SPAs é mais comum.
 error_document {
 key = "index.html"
 }
}

# Política para permitir acesso público ao conteúdo do S3 (Frontend)
resource "aws_s3_bucket_policy" "crypto_ui_policy" {
 bucket = aws_s3_bucket.crypto_ui.id
 policy = jsonencode({
 Version = "2012-10-17"
 Statement = [
 {
    Sid = "PublicReadGetObject"
    Effect = "Allow"
    Principal = "*"
    Action = ["s3:GetObject"]
    Resource = "${aws_s3_bucket.crypto_ui.arn}/*"
 }
 ]
 })
 
 # Dependência explícita para garantir que o BPA seja configurado antes da política
 depends_on = [
 aws_s3_bucket_public_access_block.crypto_ui_public_access_block,
 ]
}

# ============================
# NOVO: S3 para Imagens da API
# ============================
resource "aws_s3_bucket" "crypto_images" {
 bucket = var.image_bucket_name # 🔄 Usando variável
 
 tags = {
 Name = "crypto-api-images-bucket"
 }
}