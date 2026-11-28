module "identity" {
  source              = "../.."
  name                = var.name
  callback_urls       = var.callback_urls
  deletion_protection = var.deletion_protection
  tags                = var.tags
}

output "issuer_url" {
  value = module.identity.issuer_url
}

output "client_id" {
  value = module.identity.client_id
}

output "user_pool_id" {
  value = module.identity.user_pool_id
}
