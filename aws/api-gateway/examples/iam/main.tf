module "baseline" {
  source = "../.."

  name                = var.name
  lambda_function_arn = var.lambda_function_arn
  log_kms_key_arn     = var.log_kms_key_arn
  routes              = ["GET /items", "POST /items"]
  tags                = var.tags
}

output "api_endpoint" {
  description = "Resultado principal del ejemplo."
  value       = module.baseline.api_endpoint
}
