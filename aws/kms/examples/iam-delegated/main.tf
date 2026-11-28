module "kms" {
  source     = "../.."
  alias_name = var.alias_name
  tags       = { Environment = "poc" }
}

output "key_arn" {
  value = module.kms.key_arn
}
