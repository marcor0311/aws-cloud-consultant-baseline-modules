module "baseline" {
  source = "../.."

  table_name     = var.table_name
  kms_key_arn    = var.kms_key_arn
  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 5
  tags           = var.tags
}

output "table_name" {
  description = "Resultado principal del ejemplo."
  value       = module.baseline.table_name
}
