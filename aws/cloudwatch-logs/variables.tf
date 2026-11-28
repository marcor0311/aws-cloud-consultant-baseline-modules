variable "name" {
  description = "Nombre completo del grupo de logs."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_./#-]{1,512}$", var.name)) && !startswith(var.name, "aws/")
    error_message = "El nombre debe tener de 1 a 512 caracteres permitidos y no puede empezar por aws/."
  }
}

variable "retention_in_days" {
  description = "Días de retención. Este baseline exige un plazo finito."
  type        = number
  default     = 30
  nullable    = false

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.retention_in_days)
    error_message = "Elige un plazo de retención finito admitido por CloudWatch Logs."
  }
}

variable "kms_key_arn" {
  description = "ARN de la clave KMS simétrica regional. Null conserva el cifrado administrado por CloudWatch Logs."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/(mrk-[0-9a-f]{32}|[0-9a-f-]{36})$", var.kms_key_arn))
    error_message = "Proporciona el ARN de una clave KMS, en lugar de un alias."
  }
}

variable "tags" {
  description = "Etiquetas corporativas del grupo de logs."
  type        = map(string)
  nullable    = false
}
