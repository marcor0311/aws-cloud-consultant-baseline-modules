output "topic_arn" {
  description = "ARN del tópico para publicadores y políticas de colas suscritas."
  value       = aws_sns_topic.this.arn
  depends_on  = [aws_sns_topic_policy.this]
}

output "subscription_arns" {
  description = "Suscripciones SQS por nombre."
  value       = { for key, item in aws_sns_topic_subscription.sqs : key => item.arn }
}
