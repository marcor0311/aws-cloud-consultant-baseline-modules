module "baseline" {
  source = "../.."

  bucket_name                        = var.bucket_name
  kms_key_arn                        = var.kms_key_arn
  expiration_days                    = 365
  noncurrent_version_expiration_days = 30
  tags                               = var.tags
}

output "bucket_id" {
  description = "Resultado principal del ejemplo."
  value       = module.baseline.bucket_id
}
