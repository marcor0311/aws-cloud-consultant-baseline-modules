output "function_name" {
  description = "Nombre de la función para el consumidor."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN sin calificador de la función."
  value       = aws_lambda_function.this.arn
}

output "event_source_mapping_uuid" {
  description = "UUID del mapeo SQS si se habilita."
  value       = one(aws_lambda_event_source_mapping.sqs[*].uuid)
}
