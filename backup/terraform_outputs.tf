# URL do API Gateway
output "api_gateway_url" {
  value       = "${aws_api_gateway_stage.prod_stage.invoke_url}/"
  description = "URL base do API Gateway (Stage /prod)"
}