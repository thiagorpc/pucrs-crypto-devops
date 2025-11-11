# 1. API Base
resource "aws_api_gateway_rest_api" "crypto_gateway" {
  name        = "crypto-api-gateway"
  description = "Gateway para o backend ECS/ALB"

  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch_log_role.arn
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

# 4. Integração com ALB
resource "aws_api_gateway_integration" "alb_integration" {
  rest_api_id             = aws_api_gateway_rest_api.crypto_gateway.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_method.http_method
  
  # 1. TIPO CORRIGIDO: Deve ser HTTP_PROXY para proxying de URL
  type                    = "HTTP_PROXY" 

  # 2. URI CORRIGIDA: Usa a URL HTTPS completa do ALB (incluindo o caminho root /)
  # O ALB 'aws_lb.crypto_alb' deve ser definido em outro lugar, provavelmente em 'alb.tf'
  uri                     = "http://${aws_lb.crypto_alb.dns_name}/{proxy}" 
  
  # O método HTTP que o API Gateway usará para chamar o Backend (ALB)
  integration_http_method = "ANY" 
  
  # A integração HTTP_PROXY não precisa de 'connection_type = VPC_LINK'.
  # O API Gateway chama o ALB pela rede pública (DNS).

  tls_config {
    insecure_skip_verify = true 
  }

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

# 7. Política de Confiança: Permite que o serviço API Gateway assuma esta role
data "aws_iam_policy_document" "apigw_log_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apigw_cloudwatch_log_role" {
  name               = "crypto-apigw-cloudwatch-role"
  assume_role_policy = data.aws_iam_policy_document.apigw_log_assume_role.json
}

# 8. Política de Permissão: Permite gravar logs no CloudWatch
resource "aws_iam_role_policy_attachment" "apigw_cloudwatch_attach" {
  role       = aws_iam_role.apigw_cloudwatch_log_role.name
  # Esta é a política gerenciada da AWS que dá as permissões exatas necessárias
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# 9. Política de saída de Log
resource "aws_api_gateway_stage" "prod_stage" {
  deployment_id = aws_api_gateway_deployment.crypto_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.crypto_gateway.id
  stage_name    = "prod"

  # 🎯 NOVO: Habilita o Logging
  access_log_settings {
    # ARN do CloudWatch Log Group de destino (você pode criar um ou usar o default)
    destination_arn = "arn:aws:logs:us-east-1:202533542500:log-group:/aws/apigateway/crypto-api-prod" 
    
    # Formato dos logs (Exemplo: Logs completos)
    format = "$context.requestId $context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.integrationErrorMessage"
  }

  # Opcional: Habilita métricas detalhadas (Execution/Errors)
  xray_tracing_enabled = true
  
  # 🎯 NOVO: Define os níveis de log (INFO, ERROR, OFF)
  # log_level pode ser "INFO" para logs detalhados
  # metrics_enabled = true
  # cache_cluster_enabled = false 
}