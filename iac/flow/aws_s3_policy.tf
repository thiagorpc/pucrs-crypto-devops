# ============================
# File: ./iac/flow/aws_s3_policy.tf
# ============================

# 🎯 Desativar 'BlockPublicPolicy' para permitir a política de acesso público
resource "aws_s3_bucket_public_access_block" "frontend_public_access_block" {
  bucket = aws_s3_bucket.frontend.id

  # NECESSÁRIO: Permite que a política pública (abaixo) seja aplicada.
  block_public_policy = false

  # Manter as outras restrições
  block_public_acls       = true
  ignore_public_acls      = true
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


# Política S3 para permitir acesso SOMENTE ao CloudFront (OAC)
resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend_cdn.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_cloudfront_distribution.frontend_cdn]
}


