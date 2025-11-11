# 1. API Base
resource "aws_api_gateway_rest_api" "crypto_gateway" {
  name        = "crypto-api-gateway"
  description = "Gateway para o backend ECS/ALB"
}

# 2. Recurso Root (o path "/")
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.crypto_gateway.id
  parent_id   = aws_api_gateway_rest_api.crypto_gateway.root_resource_id
  path_part   = "{proxy+}" # Captura qualquer path (ex: /health, /users, etc.)
}

# 3. Método (ANY para capturar todos)
resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.crypto_gateway.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE" # Nenhuma autorização (pode ser ajustado)
}

# 4. Integração do Backend (ALB)
#resource "aws_api_gateway_integration" "alb_integration" {
#  rest_api_id             = aws_api_gateway_rest_api.crypto_gateway.id
#  resource_id             = aws_api_gateway_resource.proxy.id
#  http_method             = aws_api_gateway_method.proxy_method.http_method
#  type                    = "HTTP_PROXY" # Tipo de integração para serviços AWS
#
#  # Use o ARN do seu ALB Listener HTTPS (Porta 443) como endpoint
#  uri = aws_lb_listener.crypto_https_listener.arn
#
#  integration_http_method = "ANY"
#  connection_type         = "VPC_LINK" # Necessário para se conectar ao ALB dentro da sua VPC
#}

resource "aws_api_gateway_integration" "alb_integration" {
  rest_api_id             = aws_api_gateway_rest_api.crypto_gateway.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_method.http_method
  
  # 1. TIPO CORRIGIDO: Deve ser HTTP_PROXY para proxying de URL
  type                    = "HTTP_PROXY" 

  # 2. URI CORRIGIDA: Usa a URL HTTPS completa do ALB (incluindo o caminho root /)
  # O ALB 'aws_lb.crypto_alb' deve ser definido em outro lugar, provavelmente em 'alb.tf'
  uri                     = "https://${aws_lb.crypto_alb.dns_name}/{proxy}" 
  
  # O método HTTP que o API Gateway usará para chamar o Backend (ALB)
  integration_http_method = "ANY" 
  
  # A integração HTTP_PROXY não precisa de 'connection_type = VPC_LINK'.
  # O API Gateway chama o ALB pela rede pública (DNS).

}

# 5. Deployment
resource "aws_api_gateway_deployment" "crypto_deployment" {
  rest_api_id = aws_api_gateway_rest_api.crypto_gateway.id

  # Gatilho para redeploy em caso de mudança na integração/método
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy_method.id,
      aws_api_gateway_integration.alb_integration.id,
    ]))
  }
  
  # O deployment depende da integração estar configurada
  lifecycle {
    create_before_destroy = true
  }
}

# 6. Stage (Ex: /prod)
resource "aws_api_gateway_stage" "prod_stage" {
  deployment_id = aws_api_gateway_deployment.crypto_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.crypto_gateway.id
  stage_name    = "prod"
}