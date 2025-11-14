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

#######################################################
# Libera o acesso do S3 à Internet
#
#resource "aws_s3_bucket_public_access_block" "ui" {
#  bucket                  = aws_s3_bucket.frontend.id
#  block_public_acls       = false
#  block_public_policy     = false
#  ignore_public_acls      = false
#  restrict_public_buckets = false
#}

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

# Política para permitir acesso público ao conteúdo do S3 (Frontend)
#resource "aws_s3_bucket_policy" "frontend_policy" {
#  bucket = aws_s3_bucket.frontend.id
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Sid       = "PublicReadGetObject"
#        Effect    = "Allow"
#        Principal = "*"
#        Action    = ["s3:GetObject"]
#        Resource  = "${aws_s3_bucket.frontend.arn}/*"
#      }
#    ]
#  })
#
#  # Dependência explícita para garantir que o BPA seja configurado antes da política
#  depends_on = [
#    aws_s3_bucket_public_access_block.frontend_public_access_block,
#  ]
#}

# Política S3 para permitir acesso SOMENTE ao CloudFront (OAC)
resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.s3_policy_cloudfront_access.json
}

data "aws_iam_policy_document" "s3_policy_cloudfront_access" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"] 
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend_cdn.arn]
    }
  }
}