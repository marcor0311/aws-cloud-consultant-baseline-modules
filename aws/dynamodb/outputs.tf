output "table_name" {
  description = "Nombre de la tabla para configurar la aplicación."
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "ARN de la tabla para políticas IAM del proyecto."
  value       = aws_dynamodb_table.this.arn
}

output "table_id" {
  description = "Identificador de la tabla administrada."
  value       = aws_dynamodb_table.this.id
}
