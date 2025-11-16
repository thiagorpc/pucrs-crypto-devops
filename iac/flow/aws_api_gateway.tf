# ============================
# File: ./iac/flow/aws_api_gateway.tf
# ============================

# Dados dinâmicos da conta e região
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# API Gateway Base para o backend ECS/NLB
resource "aws_api_gateway_rest_api" "project_api_gateway" {
  name        = "${var.project_name}-api-gateway"
  description = "API Gateway para o backend ECS/NLB"
}

# Recurso Root com path "/{proxy+}" para capturar qualquer rota
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.project_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.project_api_gateway.root_resource_id
  path_part   = "{proxy+}"
}

# Método ANY no recurso proxy (captura todas as requisições)
resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.project_api_gateway.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# Integração do API Gateway com o NLB via VPC Link
resource "aws_api_gateway_integration" "nlb_integration" {
  depends_on = [aws_api_gateway_method.proxy_method]

  rest_api_id             = aws_api_gateway_rest_api.project_api_gateway.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_method.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.project_vpc_link.id
  uri                     = "http://${aws_lb.api_nlb.dns_name}/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# Deployment do API Gateway, redeploy é acionado automaticamente quando ha mudanças
resource "aws_api_gateway_deployment" "project_deployment" {
  rest_api_id = aws_api_gateway_rest_api.project_api_gateway.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy_method.id,
      aws_api_gateway_integration.nlb_integration.id,
      aws_api_gateway_integration.options_proxy_integration.id,
      aws_api_gateway_method.options_proxy.id, 
      aws_api_gateway_method_response.options_proxy_response.id,
      aws_api_gateway_integration_response.options_proxy_integration_response.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Group para armazenar logs do API Gateway
resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = "/aws/apigateway/${var.project_name}-api-prod"
  retention_in_days = 3
}

# IAM Role para que o API Gateway possa escrever logs no CloudWatch
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
  name               = "${var.project_name}-apigw-cloudwatch-role"
  assume_role_policy = data.aws_iam_policy_document.apigw_log_assume_role.json
}

resource "aws_iam_role_policy_attachment" "apigw_cloudwatch_attach" {
  role       = aws_iam_role.apigw_cloudwatch_log_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Configuração da conta do API Gateway para habilitar envio de logs
resource "aws_api_gateway_account" "apigw_account_settings" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch_log_role.arn

  lifecycle {
    prevent_destroy = false
  }
}

# Stage de produção (/prod) com logs ativados e X-Ray habilitado
resource "aws_api_gateway_stage" "prod_stage" {
  deployment_id = aws_api_gateway_deployment.project_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.project_api_gateway.id
  stage_name    = "prod"

  depends_on = [
    aws_api_gateway_account.apigw_account_settings,
    aws_cloudwatch_log_group.api_gw_logs,
    aws_api_gateway_deployment.project_deployment
  ]

  access_log_settings {
    destination_arn = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.api_gw_logs.name}"
    format          = "$context.requestId $context.identity.sourceIp $context.httpMethod $context.resourcePath $context.protocol $context.status $context.responseLength"
  }

  xray_tracing_enabled = true
}

# VPC Link entre API Gateway e NLB
resource "aws_api_gateway_vpc_link" "project_vpc_link" {
  name        = "${var.project_name}-nlb-link"
  description = "VPC Link entre API Gateway e NLB"
  target_arns = [aws_lb.api_nlb.arn]
}

# Configuração de métricas e logs para todos os métodos do stage
resource "aws_api_gateway_method_settings" "proxy_method_settings" {
  rest_api_id = aws_api_gateway_rest_api.project_api_gateway.id
  stage_name  = aws_api_gateway_stage.prod_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }

  depends_on = [aws_api_gateway_stage.prod_stage]
}

# Método OPTIONS para pré-voo CORS
resource "aws_api_gateway_method" "options_proxy" {
  rest_api_id   = aws_api_gateway_rest_api.project_api_gateway.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Integração MOCK para resposta do OPTIONS (pré-voo CORS)
resource "aws_api_gateway_integration" "options_proxy_integration" {
  rest_api_id = aws_api_gateway_rest_api.project_api_gateway.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options_proxy.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Resposta do método OPTIONS definindo cabeçalhos CORS
resource "aws_api_gateway_method_response" "options_proxy_response" {
  rest_api_id = aws_api_gateway_rest_api.project_api_gateway.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options_proxy.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Integração da resposta OPTIONS mapeando os cabeçalhos CORS
resource "aws_api_gateway_integration_response" "options_proxy_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.project_api_gateway.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options_proxy.http_method
  status_code = aws_api_gateway_method_response.options_proxy_response.status_code

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS,PUT,PATCH,DELETE,ANY'", 
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Origin"  = "'https://${aws_cloudfront_distribution.frontend_cdn.domain_name}'"
  }

  depends_on = [aws_api_gateway_method_response.options_proxy_response]
}

