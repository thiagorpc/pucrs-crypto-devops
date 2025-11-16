# ============================
# File: ./iac/flow/aws_s3_bucket.tf
# ============================

# Bucket S3 para hospedagem do frontend React
# Permite armazenar arquivos estaticos do UI
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend"
  tags = {
    Name = "${var.project_name}-ui-bucket"
  }

  # Permite deletar o bucket mesmo se contiver objetos
  force_destroy = true
}

# Configuração de propriedade do bucket
# Garante que todos os objetos são de propriedade do dono do bucket
resource "aws_s3_bucket_ownership_controls" "ui_ownership" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

