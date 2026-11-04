output "api_id" {
  description = "Identificador del HTTP API."
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "URL base del API; un stage distinto de $default añade su nombre al path."
  value       = aws_apigatewayv2_stage.this.invoke_url
  depends_on  = [aws_lambda_permission.api_gateway, aws_apigatewayv2_route.this]
}

output "execution_arn" {
  description = "ARN de ejecución para políticas IAM y permisos de invocación."
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "access_log_group_arn" {
  description = "ARN de los logs de acceso cifrados."
  value       = aws_cloudwatch_log_group.access.arn
}
