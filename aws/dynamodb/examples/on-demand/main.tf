module "baseline" {
  source = "../.."

  table_name                        = var.table_name
  kms_key_arn                       = var.kms_key_arn
  on_demand_max_read_request_units  = 1000
  on_demand_max_write_request_units = 500
  tags                              = var.tags
}

output "table_name" {
  description = "Resultado principal del ejemplo."
  value       = module.baseline.table_name
}
