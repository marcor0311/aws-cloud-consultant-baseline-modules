module "queue" {
  source                     = "../.."
  name                       = var.queue_name
  kms_key_arn                = var.kms_key_arn
  visibility_timeout_seconds = 120
  tags                       = { Environment = "poc" }
}

output "queue_arn" {
  value = module.queue.queue_arn
}

output "dead_letter_queue_url" {
  value = module.queue.dead_letter_queue_url
}
