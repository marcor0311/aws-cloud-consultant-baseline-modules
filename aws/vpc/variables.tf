variable "name" {
  description = "Prefijo de nombre para la VPC y sus recursos."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,40}$", var.name))
    error_message = "Usa de 2 a 41 minúsculas, dígitos o guiones."
  }
}

variable "cidr_block" {
  description = "Bloque IPv4 de la VPC. Se divide en subredes /20 por zona."
  type        = string
  default     = "10.0.0.0/16"
  nullable    = false

  validation {
    condition     = can(cidrnetmask(var.cidr_block)) && tonumber(split("/", var.cidr_block)[1]) >= 16 && tonumber(split("/", var.cidr_block)[1]) <= 18
    error_message = "Usa un bloque IPv4 válido entre /16 y /18."
  }
}

variable "availability_zones" {
  description = "Zonas de disponibilidad de la región. Se crea una subred privada por zona y, con salida a Internet, una pública."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.availability_zones) >= 2 && length(var.availability_zones) <= 3 && length(distinct(var.availability_zones)) == length(var.availability_zones)
    error_message = "Indica dos o tres zonas distintas."
  }
}

variable "internet_egress" {
  description = "Crea subredes públicas, Internet Gateway y un NAT Gateway por zona. Con false la VPC queda aislada."
  type        = bool
  default     = true
  nullable    = false
}

variable "single_nat_gateway" {
  description = "Usa un único NAT Gateway compartido para reducir costo, a cambio de depender de una zona."
  type        = bool
  default     = false
  nullable    = false
}

variable "flow_log_retention_days" {
  description = "Días de retención de los VPC Flow Logs en CloudWatch Logs."
  type        = number
  default     = 30
  nullable    = false

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.flow_log_retention_days)
    error_message = "Usa un valor de retención admitido por CloudWatch Logs."
  }
}

variable "tags" {
  description = "Etiquetas de todos los recursos."
  type        = map(string)
  default     = {}
  nullable    = false
}
