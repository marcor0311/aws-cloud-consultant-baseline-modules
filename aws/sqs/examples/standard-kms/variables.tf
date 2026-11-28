variable "aws_region" {
  description = "Región AWS del entorno consumidor."
  type        = string
  nullable    = false
}

variable "queue_name" {
  description = "Nombre de la cola Standard."
  type        = string
  nullable    = false
}

variable "kms_key_arn" {
  description = "ARN de la clave KMS simétrica compatible con SQS."
  type        = string
  nullable    = false
}
