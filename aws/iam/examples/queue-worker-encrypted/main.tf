module "baseline" {
  source = "../.."

  role_name           = var.role_name
  queue_arns          = var.queue_arns
  log_group_arns      = var.log_group_arns
  dynamodb_table_arns = var.dynamodb_table_arns
  s3_object_arns      = var.s3_object_arns
  kms_key_arns        = var.kms_key_arns
  tags                = var.tags
}

output "role_arn" {
  description = "ARN del rol de ejecución de Lambda."
  value       = module.baseline.role_arn
}
