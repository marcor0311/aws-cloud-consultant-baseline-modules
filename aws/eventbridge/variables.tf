variable "bus_name" {
  description = "Nombre del bus de eventos personalizado."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]{1,256}$", var.bus_name)) && var.bus_name != "default"
    error_message = "Usa un nombre distinto de default con letras, dígitos, puntos, guiones o guiones bajos."
  }
}

variable "rules" {
  description = "Reglas por nombre. Cada una filtra eventos con un patrón JSON y entrega a una cola SQS, un tópico SNS o una función Lambda."
  type = map(object({
    description   = optional(string, "")
    event_pattern = string
    target_type   = string
    target_arn    = string
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for rule in values(var.rules) : contains(["sqs", "sns", "lambda"], rule.target_type) && can(jsondecode(rule.event_pattern))])
    error_message = "Cada regla necesita un patrón JSON válido y un destino sqs, sns o lambda."
  }
}

variable "dead_letter_queue_arn" {
  description = "Cola SQS donde quedan los eventos que no se pudieron entregar a su destino."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:aws[a-z0-9-]*:sqs:[a-z0-9-]+:[0-9]{12}:[A-Za-z0-9_-]+$", var.dead_letter_queue_arn))
    error_message = "Indica el ARN de una cola SQS Standard."
  }
}

variable "maximum_event_age_seconds" {
  description = "Tiempo máximo de reintentos antes de enviar un evento a la DLQ."
  type        = number
  default     = 3600
  nullable    = false

  validation {
    condition     = var.maximum_event_age_seconds >= 60 && var.maximum_event_age_seconds <= 86400
    error_message = "Usa entre 60 y 86400 segundos."
  }
}

variable "archive_retention_days" {
  description = "Días que se archivan los eventos del bus para reproducirlos. Con 0 no se crea archivo."
  type        = number
  default     = 7
  nullable    = false
}

variable "tags" {
  description = "Etiquetas de todos los recursos."
  type        = map(string)
  default     = {}
  nullable    = false
}
