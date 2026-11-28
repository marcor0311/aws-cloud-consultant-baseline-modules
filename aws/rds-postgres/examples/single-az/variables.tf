variable "aws_region" {
  description = "Región AWS del entorno consumidor."
  type        = string
  nullable    = false
}

variable "identifier" {
  description = "Identificador de la instancia."
  type        = string
  nullable    = false
}

variable "vpc_id" {
  description = "VPC del proyecto."
  type        = string
  nullable    = false
}

variable "private_subnet_ids" {
  description = "Subredes privadas en dos zonas."
  type        = list(string)
  nullable    = false
}

variable "client_security_group_ids" {
  description = "Grupos de los clientes."
  type        = list(string)
  default     = []
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

variable "skip_final_snapshot" {
  description = "Omite la copia final."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Etiquetas del proyecto."
  type        = map(string)
  default     = {}
}
