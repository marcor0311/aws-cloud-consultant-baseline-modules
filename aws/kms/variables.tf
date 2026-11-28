variable "alias_name" {
  description = "Alias de la clave con prefijo alias/. AWS reserva el prefijo alias/aws/."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^alias/[a-zA-Z0-9_/-]+$", var.alias_name)) && !startswith(var.alias_name, "alias/aws/") && length(var.alias_name) <= 256
    error_message = "Especifica un alias KMS válido de hasta 256 caracteres que no empiece con alias/aws/."
  }
}

variable "description" {
  description = "Descripción visible en AWS KMS."
  type        = string
  default     = "Regional encryption key"
  nullable    = false

  validation {
    condition     = length(trimspace(var.description)) > 0 && length(var.description) <= 8192
    error_message = "La descripción debe contener entre 1 y 8192 caracteres."
  }
}

variable "deletion_window_in_days" {
  description = "Ventana de recuperación después de programar la eliminación de la clave."
  type        = number
  default     = 30
  nullable    = false

  validation {
    condition     = floor(var.deletion_window_in_days) == var.deletion_window_in_days && var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "La ventana de eliminación debe ser un entero entre 7 y 30 días."
  }
}

variable "policy_json" {
  description = "Política completa de clave en JSON. Con null, KMS aplica su política predeterminada y delega permisos a IAM de la cuenta propietaria."
  type        = string
  default     = null

  validation {
    condition = var.policy_json == null ? true : try(
      jsondecode(var.policy_json).Version == "2012-10-17" &&
      startswith(jsonencode(jsondecode(var.policy_json).Statement), "[") &&
      length(jsondecode(var.policy_json).Statement) > 0,
      false
    )
    error_message = "La política debe ser un JSON con Version 2012-10-17 y una lista Statement no vacía."
  }
}

variable "tags" {
  description = "Etiquetas de la clave."
  type        = map(string)
  default     = {}
  nullable    = false
}
