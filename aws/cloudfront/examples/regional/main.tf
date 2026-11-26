module "baseline" {
  source                = "../.."
  origin_domain_name    = var.origin_domain_name
  origin_bucket_arn     = var.origin_bucket_arn
  web_acl_arn           = var.web_acl_arn
  logging_bucket_domain = var.logging_bucket_domain
  tags                  = var.tags
  price_class           = "PriceClass_100"
}

output "origin_policy_statement" {
  value = module.baseline.origin_policy_statement
}
