module "baseline" {
  source = "../.."

  bucket_name = var.bucket_name
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

output "bucket_id" {
  description = "Resultado principal del ejemplo."
  value       = module.baseline.bucket_id
}
