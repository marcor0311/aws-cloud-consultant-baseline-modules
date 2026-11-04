variable "aws_region" {
  description = "Región del proyecto consumidor."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Etiquetas corporativas del proyecto."
  type        = map(string)
}

variable "name" {
  description = "Nombre del API del proyecto."
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN de una función Lambda existente, sin código de aplicación en este repo."
  type        = string
}

variable "log_kms_key_arn" {
  description = "ARN de una clave KMS que permita al servicio regional CloudWatch Logs."
  type        = string
}
