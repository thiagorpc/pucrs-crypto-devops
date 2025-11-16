# ============================
# File: ./iac/flow/aws_api_gateway.tf
# ============================

# Dados dinâmicos da conta e região
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

//locals {
//  # O endpoint do S3-Website omite o protocolo. Incluímos 'http://' aqui.
//  frontend_origin_url = "http://${aws_s3_bucket_website_configuration.frontend_website.website_endpoint}"
//}

# 1️⃣ API Base
resource "aws_api_gateway_rest_api" "project_api_gateway" {
  name        = "${var.project_name}-api-gateway"
  description = "API Gateway para o backend ECS/NLB"
}

# 2️⃣ Recurso Root (path "/{proxy+}")
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.project_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.project_api_gateway.root_resource_id
  path_part   = "{proxy+}" # Captura qualquer path (ex: /health, /users, etc.)
}

# 3️⃣ Método (ANY)
resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.project_api_gateway.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# 4️⃣ Integração com o NLB
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

# 5️⃣ Deployment
resource "aws_api_gateway_deployment" "project_deployment" {
  rest_api_id = aws_api_gateway_rest_api.project_api_gateway.id

  # Gatilho para redeploy em caso de mudança
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy_method.id,
      aws_api_gateway_integration.nlb_integration.id,
      aws_api_gateway_method.options_proxy.id,
      aws_api_gateway_integration.options_proxy_integration.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 6️⃣ Log Group (dinâmico, sem dependência circular)
resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = "/aws/apigateway/${var.project_name}-api-prod"
  retention_in_days = 14
}

# 7️⃣ IAM Role para Logs
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

# 8️⃣ Conta do API Gateway configurada para logs
resource "aws_api_gateway_account" "apigw_account_settings" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch_log_role.arn

  lifecycle {
    prevent_destroy = false
  }
}

# 9️⃣ Stage (ex: /prod)
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

# 🔟 VPC Link (para o NLB)
resource "aws_api_gateway_vpc_link" "project_vpc_link" {
  name        = "${var.project_name}-nlb-link"
  description = "VPC Link entre API Gateway e NLB"
  target_arns = [aws_lb.api_nlb.arn]
}

# 1️⃣1️⃣ Configuração de Logs e Métricas (Method Settings)
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

# 💡 1A. Criação do Método OPTIONS (Pré-voo CORS) no recurso {proxy+}
resource "aws_api_gateway_method" "options_proxy" {
  rest_api_id   = aws_api_gateway_rest_api.project_api_gateway.id
  resource_id   = aws_api_gateway_resource.proxy.id # No {proxy+}
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# 💡 1B. Resposta da Integração (MOCK)
resource "aws_api_gateway_integration" "options_proxy_integration" {
  rest_api_id = aws_api_gateway_rest_api.project_api_gateway.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options_proxy.http_method
  type        = "MOCK" # Intercepta e responde no API GW
}

# 💡 2A. Resposta do Método (Define os cabeçalhos CORS)
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

# 💡 2B. Resposta da Integração (Mapeamento dos valores dos cabeçalhos)
resource "aws_api_gateway_integration_response" "options_proxy_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.project_api_gateway.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options_proxy.http_method
  status_code = aws_api_gateway_method_response.options_proxy_response.status_code
  
  # Note que não há template de mapeamento necessário aqui, pois a resposta é vazia.
  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS,ANY'", 
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Origin"  = "'${aws_cloudfront_distribution.frontend_cdn.domain_name}'" # Use a variável de origem do seu frontend
  }

  depends_on = [aws_api_gateway_method_response.options_proxy_response]
}

/*

# 1. Criação do Método OPTIONS (Pré-voo CORS)
resource "aws_api_gateway_method" "options_proxy" { # 💡 Renomeado para 'proxy'
  # CORREÇÃO: Usando a referência correta da sua API
  rest_api_id   = aws_api_gateway_rest_api.project_api_gateway.id 
  # CORREÇÃO: Usando o recurso proxy, que captura todas as rotas
  resource_id   = aws_api_gateway_resource.proxy.id 
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# 2. Resposta da Integração (Mock)
resource "aws_api_gateway_integration" "options_proxy_integration" { # 💡 Renomeado
  rest_api_id = aws_api_gateway_rest_api.project_api_gateway.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options_proxy.http_method
  type        = "MOCK"
}

# 3. Resposta do Método (Define os cabeçalhos CORS)
resource "aws_api_gateway_method_response" "options_proxy_response" { # 💡 Renomeado
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

# 4. Resposta da Integração (Mapeamento dos valores dos cabeçalhos)
resource "aws_api_gateway_integration_response" "options_proxy_integration_response" { # 💡 Renomeado
  rest_api_id = aws_api_gateway_rest_api.project_api_gateway.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.options_proxy.http_method
  status_code = aws_api_gateway_method_response.options_proxy_response.status_code

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS,ANY'", 
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    
    # 🟢 CORREÇÃO DA SINTAXE E REFERÊNCIA DINÂMICA
    # O valor final deve ser uma string literal ('...') que contém a URL do frontend.
    "method.response.header.Access-Control-Allow-Origin"  = "'${aws_cloudfront_distribution.frontend_cdn.domain_name}'"
    // "'${aws_s3_bucket_website_configuration.frontend_website.website_endpoint}'"
    
    //"'${local.frontend_origin_url}'" 
  }

  depends_on = [aws_api_gateway_method_response.options_proxy_response]
}
*/