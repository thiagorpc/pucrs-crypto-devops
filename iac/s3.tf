# ============================
# S3 para Frontend React (UI)
# ============================
resource "aws_s3_bucket" "crypto_ui" {
  bucket = var.react_bucket_name # 🔄 Usando variável
  tags   = { Name = "crypto-ui-bucket" }

  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "crypto_ui_ownership" {
  bucket = aws_s3_bucket.crypto_ui.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_website_configuration" "crypto_ui_website" {
  bucket = aws_s3_bucket.crypto_ui.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

# Política para permitir acesso público ao conteúdo do S3 (Frontend)
resource "aws_s3_bucket_policy" "crypto_ui_policy" {
  bucket = aws_s3_bucket.crypto_ui.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.crypto_ui.arn}/*"
      }
    ]
  })
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