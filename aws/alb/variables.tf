variable "name" {
  description = "Nombre del balanceador. También se usa en el grupo de seguridad y el grupo de destinos."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,24}[a-z0-9]$", var.name))
    error_message = "Usa de 2 a 26 minúsculas, dígitos o guiones para reservar espacio al sufijo del grupo de destinos."
  }
}

variable "vpc_id" {
  description = "VPC de los destinos."
  type        = string
  nullable    = false
}

variable "subnet_ids" {
  description = "Subredes públicas en al menos dos zonas, o privadas si el balanceador es interno."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Un ALB requiere subredes en al menos dos zonas."
  }
}

variable "internal" {
  description = "Crea un balanceador interno sin dirección pública."
  type        = bool
  default     = false
  nullable    = false
}

variable "certificate_arn" {
  description = "Certificado de ACM para el listener HTTPS."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:aws[a-z0-9-]*:acm:[a-z0-9-]+:[0-9]{12}:certificate/[0-9a-f-]+$", var.certificate_arn))
    error_message = "Indica el ARN de un certificado de ACM."
  }
}

variable "ingress_cidr_blocks" {
  description = "Rangos IPv4 que pueden llegar al balanceador por HTTP y HTTPS."
  type        = list(string)
  default     = ["0.0.0.0/0"]
  nullable    = false

  validation {
    condition     = length(var.ingress_cidr_blocks) > 0 && alltrue([for block in var.ingress_cidr_blocks : can(cidrnetmask(block))])
    error_message = "Indica al menos un bloque IPv4 válido."
  }
}

variable "target_port" {
  description = "Puerto en el que escuchan los destinos."
  type        = number
  default     = 8080
  nullable    = false

  validation {
    condition     = var.target_port >= 1 && var.target_port <= 65535
    error_message = "El puerto debe estar entre 1 y 65535."
  }
}

variable "target_type" {
  description = "ip para Fargate y EKS, instance para EC2 o lambda."
  type        = string
  default     = "ip"
  nullable    = false

  validation {
    condition     = contains(["ip", "instance", "lambda"], var.target_type)
    error_message = "Usa ip, instance o lambda."
  }
}

variable "health_check_path" {
  description = "Ruta HTTP que responde 200 cuando el destino está sano."
  type        = string
  default     = "/health"
  nullable    = false
}

variable "security_group_ids" {
  description = "Grupos de seguridad existentes del balanceador. Con null el módulo crea uno con entrada 80 y 443 y salida a los destinos."
  type        = list(string)
  default     = null

  validation {
    condition     = var.security_group_ids == null || length(coalesce(var.security_group_ids, [])) > 0
    error_message = "Indica al menos un grupo de seguridad o deja null."
  }
}

variable "access_logs_bucket" {
  description = "Bucket S3 para los registros de acceso. Con null quedan desactivados."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Impide borrar el balanceador por error."
  type        = bool
  default     = true
  nullable    = false
}

variable "tags" {
  description = "Etiquetas de todos los recursos."
  type        = map(string)
  default     = {}
  nullable    = false
}
