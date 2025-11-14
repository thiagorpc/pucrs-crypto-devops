# Distribuição CloudFront (CDN/HTTPS com Certificado Padrão)
resource "aws_cloudfront_distribution" "frontend_cdn" {
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.frontend.id
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN para o frontend React no S3"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = aws_s3_bucket.frontend.id
    
    # FORÇA HTTPS
    viewer_protocol_policy = "redirect-to-https" 
    
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    # ESSENCIAL PARA CORS
    forwarded_values {
      query_string = false
      headers = [
        "Origin",
        "Access-Control-Request-Method",
        "Access-Control-Request-Headers"
      ]
      cookies {
        forward = "none"
      }
    }
  }
  
  # 🟢 CORREÇÃO: Usando o certificado padrão da AWS
  viewer_certificate {
    cloudfront_default_certificate = true 
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}



# Acesso Controlado à Origem (OAC)
resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  name                              = "${aws_s3_bucket.frontend.id}-oac"
  description                       = "OAC para o bucket S3 do frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}