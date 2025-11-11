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

# 4. Integração com ALB
resource "aws_api_gateway_integration" "alb_integration" {
  rest_api_id = aws_api_gateway_rest_api.crypto_gateway.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_method.http_method
  
  # 🎯 Mude o tipo de integração para AWS_PROXY (ou AWS)
  type        = "AWS_PROXY" 
  
  # A URI agora aponta para o ALB Listener (usando o ARN)
  #uri        = aws_lb_listener.crypto_https_listener.arn 
  #uri        = "arn:aws:apigateway:${var.aws_region}:elasticloadbalancing/https/${aws_lb.crypto_alb.arn}/"

  uri = "arn:aws:apigateway:${var.aws_region}:elasticloadbalancing/http/${aws_lb.crypto_alb.arn}/"
  
  # HTTPS
  #uri = "arn:aws:elasticloadbalancing:us-east-1:202533542500:listener/app/crypto-api-alb/9583492550809c53/216f279877c166ec"
  
  # ALB
  #arn:aws:elasticloadbalancing:us-east-1:202533542500:loadbalancer/app/crypto-api-alb/9583492550809c53
  
  # Mantenha o integration_http_method
  integration_http_method = "ANY" 

  # VPC_LINK para rotear o tráfego internamente
  connection_type         = "VPC_LINK" 
  connection_id           = aws_api_gateway_vpc_link.crypto_vpc_link.id
  
  # Opcional: Adicionar path mapping para o ALB
  request_parameters = {
      "integration.request.path.proxy" = "method.request.path.proxy"
  }

  # ❌ REMOVA TUDO relacionado a TLS/Certificado
  # tls_config e insecure_skip_verify não são mais necessários
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

  # 🎯 NOVO: Dependência para garantir que a Role do CloudWatch foi configurada globalmente
  depends_on = [
    aws_api_gateway_account.crypto_apigw_account_settings
  ]

  # 🎯 Habilita o Logging
  access_log_settings {
    # ARN do CloudWatch Log Group de destino (você pode criar um ou usar o default)
    destination_arn = "arn:aws:logs:us-east-1:202533542500:log-group:/aws/apigateway/crypto-api-prod" 
    
    # Formato dos logs (Exemplo: Logs completos)
    format = "$context.requestId $context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.integrationErrorMessage"
  }

  # Opcional: Habilita métricas detalhadas (Execution/Errors)
  xray_tracing_enabled = true
  
  # 🎯 Define os níveis de log (INFO, ERROR, OFF)
  # log_level pode ser "INFO" para logs detalhados
  #variables = {
  #  "logging_level" = "DEBUG",
  #  "metrics_enabled" = true
  #}

  # cache_cluster_enabled = false 
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


resource "aws_api_gateway_account" "crypto_apigw_account_settings" {
  # 🎯 NOVO: Define a Role para o CloudWatch Logs em nível de conta/região
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch_log_role.arn
}

# Crie o VPC Link que se conecta aos seus subnets do ALB
#resource "aws_api_gateway_vpc_link" "crypto_vpc_link" {
#  name        = "crypto-alb-link"
#  target_arns = [aws_lb.crypto_alb.arn] 
#}

resource "aws_api_gateway_vpc_link" "crypto_vpc_link" {
  name= "crypto-alb-link"
  description = "VPC Link entre API Gateway e ALB"
  //type = "VPC_LINK"
  #target_arns = [aws_lb.crypto_alb.arn] 
  #target_arns = ["arn:aws:elasticloadbalancing:us-east-1:202533542500:listener/app/crypto-api-alb/9583492550809c53/216f279877c166ec"] 
  target_arns = [aws_lb.crypto_alb.arn]

  
}

# 10. Configuração de Logs e Métricas de Execução (Method Settings)
resource "aws_api_gateway_method_settings" "proxy_method_settings" {
  rest_api_id = aws_api_gateway_rest_api.crypto_gateway.id
  stage_name  = aws_api_gateway_stage.prod_stage.stage_name
  
  # Aplica a configuração a todos os métodos e recursos no Stage
  method_path = "*/*" 

  settings {
    # 🎯 Define o nível de log de EXECUÇÃO
    metrics_enabled = true
    logging_level   = "INFO" # Use "INFO" ou "ERROR". "DEBUG" gera logs muito volumosos.
    data_trace_enabled = true # Incluir corpo da requisição/resposta nos logs de INFO/DEBUG
  }
  
  # O deployment precisa da nova Task Definition
  depends_on = [aws_api_gateway_deployment.crypto_deployment]
}