variable "aws_region" {
  description = "Región AWS del entorno consumidor."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Prefijo de nombre de la red."
  type        = string
  nullable    = false
}

variable "availability_zones" {
  description = "Dos o tres zonas de la región."
  type        = list(string)
  nullable    = false
}

variable "tags" {
  description = "Etiquetas del proyecto."
  type        = map(string)
  default     = {}
}
