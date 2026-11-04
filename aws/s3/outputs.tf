output "bucket_id" {
  description = "Nombre del bucket, disponible después de configurar los controles del módulo."
  value       = aws_s3_bucket.this.id
  depends_on = [
    aws_s3_bucket_public_access_block.this,
    aws_s3_bucket_ownership_controls.this,
    aws_s3_bucket_server_side_encryption_configuration.this,
    aws_s3_bucket_versioning.this,
    aws_s3_bucket_lifecycle_configuration.this,
    aws_s3_bucket_policy.require_tls,
    aws_s3_bucket_logging.this,
  ]
}

output "bucket_arn" {
  description = "ARN para políticas IAM del proyecto consumidor."
  value       = aws_s3_bucket.this.arn
}

output "bucket_regional_domain_name" {
  description = "Dominio regional para integraciones privadas autorizadas."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}
