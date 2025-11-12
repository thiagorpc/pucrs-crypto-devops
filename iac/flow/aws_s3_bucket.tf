# ============================
# File: ./iac/flow/aws_s3_bucket.tf
# ============================

# ============================
# S3 para Frontend React (UI)
# ============================
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend"
  tags   = { Name = "${var.project_name}-ui-bucket" }

  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "ui_ownership" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# 🎯 CORREÇÃO: Desativar 'BlockPublicPolicy' para permitir a política de acesso público
resource "aws_s3_bucket_public_access_block" "frontend_public_access_block" {
  bucket = aws_s3_bucket.frontend.id

  # NECESSÁRIO: Permite que a política pública (abaixo) seja aplicada.
  block_public_policy = false

  # Manter as outras restrições
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = false
}


resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
  
  # Usar index.html para SPAs é mais comum.
  error_document {
    key = "index.html"
  }
}

# Política para permitir acesso público ao conteúdo do S3 (Frontend)
resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })

  # Dependência explícita para garantir que o BPA seja configurado antes da política
  depends_on = [
    aws_s3_bucket_public_access_block.frontend_public_access_block,
  ]
}

resource "aws_s3_bucket_public_access_block" "ui" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ============================
# NOVO: S3 onde as imagens da aplicação serão armazenadas
# ============================
resource "aws_s3_bucket" "images" {
  # ""
  bucket = "${var.project_name}-api-images"

  tags = {
    Name = "${var.project_name}-api-images-bucket"
  }
}
