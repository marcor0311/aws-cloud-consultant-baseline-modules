variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "role_name" {
  type = string
}

variable "queue_arns" {
  type = set(string)
}

variable "log_group_arns" {
  type = set(string)
}

variable "dynamodb_table_arns" {
  type = set(string)
}

variable "s3_object_arns" {
  type    = set(string)
  default = []
}

variable "kms_key_arns" {
  type    = set(string)
  default = []
}

variable "tags" {
  type = map(string)
}
