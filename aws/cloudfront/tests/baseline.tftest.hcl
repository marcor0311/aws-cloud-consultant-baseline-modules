mock_provider "aws" {
  mock_resource "aws_cloudfront_distribution" {
    defaults = { arn = "arn:aws:cloudfront::123456789012:distribution/EXAMPLE" }
  }
}
variables {
  origin_domain_name    = "example-content.s3.us-east-1.amazonaws.com"
  origin_bucket_arn     = "arn:aws:s3:::example-content"
  web_acl_arn           = "arn:aws:wafv2:us-east-1:123456789012:global/webacl/example/12345678-1234-1234-1234-123456789012"
  logging_bucket_domain = "example-cloudfront-logs.s3.amazonaws.com"
  tags                  = { Project = "example", Environment = "dev", Owner = "platform", CostCenter = "engineering" }
}
run "secure_defaults" {
  command = apply
  assert {
    condition     = aws_cloudfront_origin_access_control.this.signing_behavior == "always" && aws_cloudfront_origin_access_control.this.signing_protocol == "sigv4" && one(aws_cloudfront_distribution.this.origin).origin_access_control_id == aws_cloudfront_origin_access_control.this.id
    error_message = "El origen requiere OAC con firma SigV4."
  }
  assert {
    condition     = one(aws_cloudfront_distribution.this.default_cache_behavior).viewer_protocol_policy == "redirect-to-https" && toset(one(aws_cloudfront_distribution.this.default_cache_behavior).allowed_methods) == toset(["GET", "HEAD"]) && aws_cloudfront_distribution.this.web_acl_id == var.web_acl_arn && one(aws_cloudfront_distribution.this.logging_config).bucket == var.logging_bucket_domain
    error_message = "HTTPS, lectura, WAF y logs son obligatorios."
  }
  assert {
    condition     = output.origin_policy_statement.Condition.StringEquals["AWS:SourceArn"] == aws_cloudfront_distribution.this.arn && output.origin_policy_statement.Resource == "${var.origin_bucket_arn}/*" && output.origin_policy_statement.Action == "s3:GetObject"
    error_message = "El acceso se limita a esta distribución y a lectura."
  }
}
run "global_profile" {
  command = plan
  variables { price_class = "PriceClass_All" }
  assert {
    condition     = aws_cloudfront_distribution.this.price_class == "PriceClass_All"
    error_message = "La cobertura debe respetar el perfil."
  }
}
run "reject_website_origin" {
  command = plan
  variables { origin_domain_name = "example-content.s3-website-us-east-1.amazonaws.com" }
  expect_failures = [var.origin_domain_name]
}
run "reject_mismatched_bucket" {
  command = plan
  variables { origin_bucket_arn = "arn:aws:s3:::different-content" }
  expect_failures = [aws_cloudfront_distribution.this]
}
