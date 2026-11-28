output "user_pool_id" {
  description = "Identificador del grupo de usuarios."
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "ARN para autorizadores de API Gateway."
  value       = aws_cognito_user_pool.this.arn
}

output "issuer_url" {
  description = "Emisor OIDC para autorizadores JWT de API Gateway HTTP."
  value       = "https://${aws_cognito_user_pool.this.endpoint}"
}

output "client_id" {
  description = "Cliente público de la aplicación web; es también la audiencia del JWT."
  value       = aws_cognito_user_pool_client.this.id
}
