variable "aws_region" {
  description = "Región AWS del entorno consumidor."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Nombre del grupo de usuarios."
  type        = string
  nullable    = false
}

variable "callback_urls" {
  description = "URL de retorno de la aplicación."
  type        = list(string)
  nullable    = false
}

variable "deletion_protection" {
  description = "Protección contra borrado."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Etiquetas del proyecto."
  type        = map(string)
  default     = {}
}
