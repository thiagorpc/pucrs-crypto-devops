# ============================
# File: ./iac/flow/aws_s3_policy.tf
# ============================

# Configuração de bloqueio de acesso publico do bucket Frontend
# Permite aplicação de políticas publicas específicas (como CloudFront OAC)
resource "aws_s3_bucket_public_access_block" "frontend_public_access_block" {
  bucket = aws_s3_bucket.frontend.id

  # Permite que a política publica definida abaixo seja aplicada
  block_public_policy = false

  # Mantém outras restrições de segurança
  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# Bucket S3 para armazenar imagens da aplicação
resource "aws_s3_bucket" "images" {
  bucket = "${var.project_name}-api-images"

  tags = {
    Name = "${var.project_name}-api-images-bucket"
  }
}

# Política S3 para permitir acesso somente ao CloudFront via OAC
resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowCloudFrontOAC",
        Effect = "Allow",
        Principal = { Service = "cloudfront.amazonaws.com" },
        Action    = ["s3:GetObject"],
        Resource  = "${aws_s3_bucket.frontend.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend_cdn.arn
          }
        }
      }
    ]
  })

  # Garante que a distribuição CloudFront esteja criada antes de aplicar a política
  depends_on = [aws_cloudfront_distribution.frontend_cdn]
}

