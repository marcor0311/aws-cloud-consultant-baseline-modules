output "queue_arn" {
  description = "ARN de la cola fuente, disponible después de aplicar sus políticas."
  value       = aws_sqs_queue.this.arn
  depends_on  = [aws_sqs_queue_policy.this, aws_sqs_queue_redrive_policy.this]
}

output "queue_url" {
  description = "URL de la cola fuente, disponible después de aplicar sus políticas."
  value       = aws_sqs_queue.this.url
  depends_on  = [aws_sqs_queue_policy.this, aws_sqs_queue_redrive_policy.this]
}

output "dead_letter_queue_arn" {
  description = "ARN de la cola de errores."
  value       = aws_sqs_queue.dead_letter.arn
  depends_on  = [aws_sqs_queue_policy.dead_letter, aws_sqs_queue_redrive_allow_policy.dead_letter]
}

output "dead_letter_queue_url" {
  description = "URL para inspección y redrive de mensajes fallidos."
  value       = aws_sqs_queue.dead_letter.url
  depends_on  = [aws_sqs_queue_policy.dead_letter, aws_sqs_queue_redrive_allow_policy.dead_letter]
}
