variable "tags" {
  description = "Etiquetas corporativas: Project, Environment, Owner y CostCenter; admite etiquetas adicionales."
  type        = map(string)
  nullable    = false

  validation {
    condition = alltrue([
      for key in ["Project", "Environment", "Owner", "CostCenter"] :
      try(length(trimspace(var.tags[key])) > 0, false)
    ])
    error_message = "Project, Environment, Owner y CostCenter deben tener valores no vacíos."
  }

  validation {
    condition     = contains(["dev", "test", "stage", "prod"], lookup(var.tags, "Environment", ""))
    error_message = "Environment debe ser dev, test, stage o prod."
  }
}

variable "bucket_name" {
  description = "Nombre único global del bucket; minúsculas, números y guiones, sin puntos."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "El nombre debe tener entre 3 y 63 caracteres DNS seguros, sin puntos."
  }
}

variable "kms_key_arn" {
  description = "ARN de una clave KMS corporativa existente, en la región del bucket, con permisos para sus consumidores."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:(aws|aws-us-gov|aws-cn):kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$", var.kms_key_arn))
    error_message = "Proporciona el ARN de una clave KMS; no un alias ni un identificador aislado."
  }
}

variable "versioning_enabled" {
  description = "Habilitar versionado; desactivarlo requiere una decisión explícita del proyecto."
  type        = bool
  default     = true
  nullable    = false
}

variable "noncurrent_version_expiration_days" {
  description = "Días para eliminar versiones anteriores; null conserva todas las versiones."
  type        = number
  default     = null

  validation {
    condition = var.noncurrent_version_expiration_days == null ? true : (
      var.versioning_enabled && var.noncurrent_version_expiration_days >= 1 &&
      floor(var.noncurrent_version_expiration_days) == var.noncurrent_version_expiration_days
    )
    error_message = "La expiración requiere versionado y un número entero positivo de días."
  }
}

variable "expiration_days" {
  description = "Días para expirar objetos actuales; null no establece expiración. Con versionado crea marcadores de eliminación."
  type        = number
  default     = null

  validation {
    condition     = var.expiration_days == null ? true : var.expiration_days >= 1 && floor(var.expiration_days) == var.expiration_days
    error_message = "La expiración debe ser un número entero positivo de días."
  }
}

variable "access_logs" {
  description = "Destino opcional de logs de acceso S3: bucket existente y prefijo. El destino debe permitir entregas de logs."
  type = object({
    bucket = string
    prefix = optional(string, "s3/")
  })
  default = null

  validation {
    condition = var.access_logs == null ? true : (
      length(trimspace(var.access_logs.bucket)) > 0 && var.access_logs.bucket != var.bucket_name
    )
    error_message = "El destino de logs debe ser un bucket existente distinto del bucket del módulo."
  }
}
