output "distribution_id" {
  description = "ID de la distribución."
  value       = aws_cloudfront_distribution.this.id
}
output "domain_name" {
  description = "Dominio HTTPS administrado por CloudFront."
  value       = aws_cloudfront_distribution.this.domain_name
}
output "origin_policy_statement" {
  description = "Declaración que se incorpora a la política existente del bucket."
  value = {
    Sid       = "AllowCloudFrontRead"
    Effect    = "Allow"
    Principal = { Service = "cloudfront.amazonaws.com" }
    Action    = "s3:GetObject"
    Resource  = "${var.origin_bucket_arn}/*"
    Condition = { StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.this.arn } }
  }
}
