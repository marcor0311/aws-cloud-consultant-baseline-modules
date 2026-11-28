variable "aws_region" {
  description = "Región AWS del entorno consumidor."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Nombre del repositorio."
  type        = string
  nullable    = false
}

variable "force_delete" {
  description = "Permite borrar el repositorio con imágenes."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Etiquetas del proyecto."
  type        = map(string)
  default     = {}
}
