variable "aws_region" {
  description = "Región del proyecto consumidor."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Etiquetas corporativas del proyecto."
  type        = map(string)
}

variable "table_name" {
  description = "Nombre de la tabla del proyecto."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN de una clave KMS corporativa existente."
  type        = string
}
