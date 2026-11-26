resource "aws_cloudfront_origin_access_control" "this" {
  name                              = trim(substr(replace(var.origin_bucket_arn, "arn:aws:s3:::", ""), 0, 64), ".")
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true
  price_class     = var.price_class
  web_acl_id      = var.web_acl_arn
  tags            = var.tags

  origin {
    domain_name              = var.origin_domain_name
    origin_id                = "private-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    target_origin_id       = "private-s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    compress               = true
  }

  logging_config {
    bucket          = var.logging_bucket_domain
    include_cookies = false
    prefix          = "cloudfront/"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  lifecycle {
    precondition {
      condition     = startswith(var.origin_domain_name, "${trimprefix(var.origin_bucket_arn, "arn:aws:s3:::")}.s3.") && length(split(".s3.", var.origin_domain_name)) == 2
      error_message = "El dominio y el ARN deben corresponder al mismo bucket."
    }
  }
}
