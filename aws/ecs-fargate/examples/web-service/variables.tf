variable "aws_region" {
  description = "Región AWS del entorno consumidor."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Nombre del servicio."
  type        = string
  nullable    = false
}

variable "image" {
  description = "Imagen con etiqueta concreta."
  type        = string
  nullable    = false
}

variable "vpc_id" {
  description = "VPC del proyecto."
  type        = string
  nullable    = false
}

variable "private_subnet_ids" {
  description = "Subredes privadas."
  type        = list(string)
  nullable    = false
}

variable "alb_security_group_id" {
  description = "Grupo del ALB que llama al servicio."
  type        = string
  default     = null
}

variable "target_group_arn" {
  description = "Grupo de destinos del ALB."
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "Grupos existentes. Con null el módulo crea el suyo."
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Etiquetas del proyecto."
  type        = map(string)
  default     = {}
}
