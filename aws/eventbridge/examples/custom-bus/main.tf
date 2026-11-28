module "events" {
  source                = "../.."
  bus_name              = var.bus_name
  dead_letter_queue_arn = var.dead_letter_queue_arn
  rules = {
    order-created = {
      description   = "Pedidos creados por la API"
      event_pattern = jsonencode({ source = ["poc.orders"], detail-type = ["OrderCreated"] })
      target_type   = "sqs"
      target_arn    = var.orders_queue_arn
    }
  }
  tags = var.tags
}

output "bus_name" {
  value = module.events.bus_name
}

output "rule_arns" {
  value = module.events.rule_arns
}
