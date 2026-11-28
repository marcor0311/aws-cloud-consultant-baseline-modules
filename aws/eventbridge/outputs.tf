output "bus_name" {
  description = "Nombre del bus para PutEvents."
  value       = aws_cloudwatch_event_bus.this.name
}

output "bus_arn" {
  description = "ARN del bus para permisos events:PutEvents de los productores."
  value       = aws_cloudwatch_event_bus.this.arn
}

output "rule_arns" {
  description = "ARN de cada regla. Las colas y tópicos destino deben autorizar a events.amazonaws.com con este ARN como origen."
  value       = { for name, rule in aws_cloudwatch_event_rule.this : name => rule.arn }
}
