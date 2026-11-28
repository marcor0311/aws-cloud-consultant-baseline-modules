variable "identifier" {
  description = "Identificador de la instancia. También nombra el grupo de subredes, de parámetros y de seguridad."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,50}[a-z0-9]$", var.identifier)) && !strcontains(var.identifier, "--")
    error_message = "Empieza con letra; usa hasta 52 minúsculas, dígitos o guiones sin dobles guiones."
  }
}

variable "vpc_id" {
  description = "VPC de la base de datos."
  type        = string
  nullable    = false
}

variable "subnet_ids" {
  description = "Subredes privadas en al menos dos zonas."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "RDS requiere subredes en al menos dos zonas."
  }
}

variable "client_security_group_ids" {
  description = "Grupos de los clientes autorizados a conectarse por el puerto 5432, por ejemplo el de ECS o Lambda."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "security_group_ids" {
  description = "Grupos existentes de la base de datos. Con null el módulo crea uno que acepta a client_security_group_ids."
  type        = list(string)
  default     = null
}

variable "engine_version" {
  description = "Versión mayor de PostgreSQL. Las menores se actualizan en la ventana de mantenimiento."
  type        = string
  default     = "17"
  nullable    = false

  validation {
    condition     = contains(["16", "17"], var.engine_version)
    error_message = "Usa PostgreSQL 16 o 17."
  }
}

variable "instance_class" {
  description = "Clase de instancia. Graviton (t4g, m7g, r7g) reduce costo."
  type        = string
  default     = "db.t4g.micro"
  nullable    = false

  validation {
    condition     = startswith(var.instance_class, "db.")
    error_message = "Usa una clase db.*."
  }
}

variable "allocated_storage_gb" {
  description = "Almacenamiento gp3 inicial en GB."
  type        = number
  default     = 20
  nullable    = false

  validation {
    condition     = var.allocated_storage_gb >= 20 && var.allocated_storage_gb <= 65536
    error_message = "Usa entre 20 y 65536 GB."
  }
}

variable "max_allocated_storage_gb" {
  description = "Límite de crecimiento automático del almacenamiento."
  type        = number
  default     = 100
  nullable    = false
}

variable "multi_az" {
  description = "Mantiene una réplica en espera en otra zona con conmutación automática."
  type        = bool
  default     = false
  nullable    = false
}

variable "database_name" {
  description = "Base de datos inicial."
  type        = string
  default     = "app"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.database_name))
    error_message = "Empieza con letra y usa minúsculas, dígitos o guiones bajos."
  }
}

variable "kms_key_arn" {
  description = "Clave KMS para cifrar almacenamiento, copias y el secreto maestro. Con null se usan las claves administradas por AWS."
  type        = string
  default     = null
}

variable "backup_retention_days" {
  description = "Días de copias automáticas con recuperación a un punto en el tiempo."
  type        = number
  default     = 7
  nullable    = false

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Usa entre 1 y 35 días; cero desactiva las copias."
  }
}

variable "deletion_protection" {
  description = "Impide borrar la instancia por error."
  type        = bool
  default     = true
  nullable    = false
}

variable "skip_final_snapshot" {
  description = "Omite la copia final al destruir. Solo para entornos efímeros."
  type        = bool
  default     = false
  nullable    = false
}

variable "tags" {
  description = "Etiquetas de todos los recursos."
  type        = map(string)
  default     = {}
  nullable    = false
}
