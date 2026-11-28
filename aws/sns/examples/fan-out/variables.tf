variable "aws_region" {
  description = "Región AWS del entorno consumidor."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Nombre del tópico."
  type        = string
  nullable    = false
}

variable "kms_key_arn" {
  description = "Clave KMS del tópico."
  type        = string
  nullable    = false
}

variable "queue_arns" {
  description = "Colas suscritas por nombre."
  type        = map(string)
  nullable    = false
}

variable "tags" {
  description = "Etiquetas del proyecto."
  type        = map(string)
  default     = {}
}
