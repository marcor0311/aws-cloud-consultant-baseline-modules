module "topic" {
  source            = "../.."
  name              = var.name
  sqs_subscriptions = var.queue_arns
  tags              = var.tags
}

output "topic_arn" {
  value = module.topic.topic_arn
}
