# ============================
# File: ./iac/flow/aws_cloudfront.tf
# ============================

# Distribuição CloudFront para o frontend React hospedado no S3
# Fornece CDN, HTTPS, cache e configuração de CORS
resource "aws_cloudfront_distribution" "frontend_cdn" {
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "S3-Origin-${aws_s3_bucket.frontend.bucket_regional_domain_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN para o frontend React no S3"
  default_root_object = "index.html"

  # Comportamento padrão de cache e requisições
  default_cache_behavior {
    allowed_methods   = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]
    cached_methods    = ["GET", "HEAD"]
    target_origin_id  = "S3-Origin-${aws_s3_bucket.frontend.bucket_regional_domain_name}"

    # Força redirecionamento para HTTPS
    viewer_protocol_policy = "redirect-to-https"

    # Configuração de TTLs do cache
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    # Configuração essencial para CORS
    forwarded_values {
      query_string = true
      headers = [
        "Origin",
        "Access-Control-Request-Method",
        "Access-Control-Request-Headers",
        "Authorization",
        "Content-Type"
      ]
      cookies {
        forward = "none"
      }
    }
  }

  # Certificado HTTPS padrão da AWS
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Restrições geograficas (nenhuma restrição aplicada)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# Controle de Acesso à Origem (OAC) para o bucket S3
# Permite que apenas o CloudFront acesse o bucket S3 diretamente
resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  name                              = "${aws_s3_bucket.frontend.id}-frontend-oac"
  description                       = "OAC para o bucket S3 do frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

