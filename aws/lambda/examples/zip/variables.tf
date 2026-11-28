variable "aws_region" { type = string }
variable "function_name" { type = string }
variable "role_arn" { type = string }
variable "log_group_name" { type = string }
variable "filename" { type = string }
variable "tags" { type = map(string) }
