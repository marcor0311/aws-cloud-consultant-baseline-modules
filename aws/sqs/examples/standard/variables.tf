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

variable "source_bucket_arn" {
  description = "ARN exacto del bucket S3 productor."
  type        = string
  nullable    = false
}

variable "source_account_id" {
  description = "Cuenta propietaria del bucket S3 productor."
  type        = string
  nullable    = false
}
