variable "aws_region" { type = string }
variable "origin_domain_name" { type = string }
variable "origin_bucket_arn" { type = string }
variable "web_acl_arn" { type = string }
variable "logging_bucket_domain" { type = string }
variable "tags" { type = map(string) }
