variable "aws_region" {
  type = string
}

variable "name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = set(string)
}

variable "iam_role_arns" {
  type = object({
    cluster       = string
    nodes         = string
    administrator = string
  })
}

variable "kms_key_arns" {
  type = object({
    secrets = string
    logs    = string
  })
}

variable "tags" {
  type = map(string)
}
