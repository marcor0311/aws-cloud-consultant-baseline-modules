variable "aws_region" {
  description = "Región AWS del entorno consumidor."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Nombre del balanceador."
  type        = string
  nullable    = false
}

variable "vpc_id" {
  description = "VPC del proyecto."
  type        = string
  nullable    = false
}

variable "public_subnet_ids" {
  description = "Subredes públicas en dos zonas."
  type        = list(string)
  nullable    = false
}

variable "certificate_arn" {
  description = "Certificado de ACM del dominio."
  type        = string
  nullable    = false
}

variable "security_group_ids" {
  description = "Grupos existentes. Con null el módulo crea el suyo."
  type        = list(string)
  default     = null
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
