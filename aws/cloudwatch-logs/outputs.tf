output "log_group_name" {
  description = "Nombre del grupo, para configurar el destino de logs del consumidor."
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "ARN exacto del grupo sin comodín. El consumidor puede derivar los ARNs de sus streams."
  value       = aws_cloudwatch_log_group.this.arn
}
