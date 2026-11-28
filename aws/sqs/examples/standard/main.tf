module "queue" {
  source = "../.."
  name   = var.queue_name
  s3_source = {
    bucket_arn = var.source_bucket_arn
    account_id = var.source_account_id
  }
  tags = { Environment = "poc" }
}

output "queue_arn" {
  value = module.queue.queue_arn
}

output "dead_letter_queue_url" {
  value = module.queue.dead_letter_queue_url
}
