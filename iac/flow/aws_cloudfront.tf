# ============================
# File: ./iac/flow/aws_cloudfront.tf
# ============================

# --- ORIGENS DA DISTRIBUIÇÃO ---
# (Assumimos que o endpoint do API Gateway é fornecido aqui, 
# substituindo o 'api_gateway_endpoint_placeholder')

# 1. Origem S3 (Frontend Estático)
resource "aws_cloudfront_distribution" "frontend_cdn" {
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "frontend-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
  }

  # 2. Origem API Gateway (Requisições Dinâmicas)
  origin {
    # ASSUMIMOS que você tem uma variável ou recurso que fornece o hostname do API Gateway
    # Exemplo: aws_apigatewayv2_api.crypto_api.api_endpoint (apenas o hostname, ex: a1b2c3d4e5.execute-api.us-east-1.amazonaws.com)
    # ATENÇÃO: Substitua 'var.api_gateway_domain_name' pelo recurso real da sua API.
    domain_name              = aws_api_gateway_stage.prod_stage.invoke_url 
    origin_id                = "api-gateway-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN para o frontend React e API Gateway"
  default_root_object = "index.html"

  # --- COMPORTAMENTO PADRÃO (DEFAULT BEHAVIOR) - APENAS S3 (ALTA CACHEABILIDADE) ---
  # Aplica-se a TODO o tráfego que não é /api/*
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"] # Métodos GET/HEAD para arquivos estáticos
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "frontend-s3-origin"

    # Use políticas gerenciadas para máximo desempenho e segurança.
    # O S3 não precisa de headers ou query strings complexos.
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
    origin_request_policy_id = "b689b0a8-53f7-4a0b-8868-xxxxxxxxxxxx" # Managed-OnlyAcceptHeaders (placeholder - ou não use)

    viewer_protocol_policy = "redirect-to-https" 
  }
  
  # --- COMPORTAMENTO ORDENADO (ORDERED BEHAVIOR) - PARA API GATEWAY (SEM CACHE / CORS) ---
  # Aplica-se especificamente ao caminho da API: /api/*
  ordered_cache_behavior {
    path_pattern = "/api/*" # Ajuste o padrão da rota da sua API conforme necessário
    target_origin_id = "api-gateway-origin"
    
    # 🚨 SOLUÇÃO PARA CORS E POST:
    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"] # Cache OPTIONS para evitar preflight em cache

    # 1. POLÍTICA DE CACHE: Não armazena em cache (TTL=0) para requisições API
    # Usamos o Managed-AllViewerExceptHostHeader para forwardar headers necessários para o Origin
    cache_policy_id        = "4135ea2d-6df8-44a3-9df6-4b5be845e2c7" # Managed-CachingDisabled

    # 2. POLÍTICA DE REQUISIÇÃO DE ORIGEM: ESSENCIAL PARA CORS!
    # O Managed-CORS-S3Origin reencaminha os headers CORS (Origin, Authorization, etc.)
    origin_request_policy_id = "b689b0a8-53f7-4a0b-8868-47c38bb22017" # Managed-CORS-S3Origin
    
    viewer_protocol_policy = "redirect-to-https" 
    
    # TTLs zerados para garantir que respostas dinâmicas e CORS não sejam cacheadas.
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
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

# Acesso Controlado à Origem (OAC) (Mantido para o S3)
resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  name                              = "${aws_s3_bucket.frontend.id}-frontend-oac"
  description                       = "OAC para o bucket S3 do frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}