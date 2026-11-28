variable "function_name" {
  description = "Nombre de la función Lambda."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{1,64}$", var.function_name))
    error_message = "Usa un nombre de Lambda válido de hasta 64 caracteres."
  }
}

variable "role_arn" {
  description = "ARN del rol de ejecución. El consumidor concede sus permisos de logs y recursos."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:[^:]+:iam::[0-9]{12}:role/.+$", var.role_arn))
    error_message = "Proporciona el ARN de un rol IAM."
  }
}

variable "log_group_name" {
  description = "Nombre del grupo CloudWatch Logs preaprovisionado."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_./#-]{1,512}$", var.log_group_name)) && !startswith(var.log_group_name, "aws/")
    error_message = "Proporciona un nombre válido de grupo de logs compatible con Lambda."
  }
}

variable "filename" {
  description = "Ruta local al ZIP producido por el consumidor antes del plan y del apply."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.filename)) > 0
    error_message = "Proporciona la ruta del paquete ZIP."
  }
}

variable "source_code_hash" {
  description = "SHA-256 del ZIP codificado en Base64. Por defecto se calcula a partir de filename."
  type        = string
  default     = null

  validation {
    condition     = var.source_code_hash == null || can(regex("^[A-Za-z0-9+/]{43}=$", var.source_code_hash))
    error_message = "Proporciona el SHA-256 de los bytes del ZIP codificado en Base64."
  }
}

variable "handler" {
  description = "Punto de entrada del runtime en el paquete."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.handler)) > 0
    error_message = "Proporciona el handler del paquete."
  }
}

variable "runtime" {
  description = "Identificador de un runtime de Lambda compatible con ZIP y x86_64."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.runtime)) > 0
    error_message = "Proporciona un runtime de Lambda."
  }
}

variable "environment_variables" {
  description = "Configuración de entorno no secreta. Sus valores pueden quedar en el estado de Terraform."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "memory_size" {
  description = "Memoria asignada en MiB."
  type        = number
  default     = 128
  nullable    = false

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240 && floor(var.memory_size) == var.memory_size
    error_message = "Selecciona un número entero de MiB entre 128 y 10240."
  }
}

variable "timeout" {
  description = "Tiempo máximo por invocación en segundos."
  type        = number
  default     = 30
  nullable    = false

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900 && floor(var.timeout) == var.timeout
    error_message = "Selecciona un timeout entero de 1 a 900 segundos."
  }
}

variable "reserved_concurrent_executions" {
  description = "Límite de concurrencia reservado para la función. Null usa el pool sin reserva."
  type        = number
  default     = null

  validation {
    condition = var.reserved_concurrent_executions == null ? true : (
      var.reserved_concurrent_executions >= 0 &&
      floor(var.reserved_concurrent_executions) == var.reserved_concurrent_executions
    )
    error_message = "Selecciona un límite entero no negativo."
  }
}

variable "sqs_event_source" {
  description = "Cola SQS Standard para invocación por lotes. Usa la visibilidad de la cola real."
  type = object({
    queue_arn                          = string
    visibility_timeout_seconds         = number
    batch_size                         = optional(number, 10)
    maximum_batching_window_in_seconds = optional(number, 0)
  })
  default = null

  validation {
    condition = var.sqs_event_source == null ? true : (
      can(regex("^arn:[^:]+:sqs:[^:]+:[0-9]{12}:[A-Za-z0-9_-]{1,80}$", var.sqs_event_source.queue_arn)) &&
      try(
        var.sqs_event_source.visibility_timeout_seconds >= 0 &&
        var.sqs_event_source.visibility_timeout_seconds <= 43200 &&
        floor(var.sqs_event_source.visibility_timeout_seconds) == var.sqs_event_source.visibility_timeout_seconds,
        false
      ) &&
      var.sqs_event_source.batch_size >= 1 &&
      var.sqs_event_source.batch_size <= 10000 &&
      floor(var.sqs_event_source.batch_size) == var.sqs_event_source.batch_size &&
      var.sqs_event_source.maximum_batching_window_in_seconds >= 0 &&
      var.sqs_event_source.maximum_batching_window_in_seconds <= 300 &&
      floor(var.sqs_event_source.maximum_batching_window_in_seconds) == var.sqs_event_source.maximum_batching_window_in_seconds &&
      (var.sqs_event_source.batch_size <= 10 || var.sqs_event_source.maximum_batching_window_in_seconds >= 1)
    )
    error_message = "Usa una cola SQS Standard, visibilidad de 0 a 43200 s y un lote de 1 a 10000. Los lotes de más de 10 exigen una ventana de 1 a 300 s."
  }
}

variable "tags" {
  description = "Etiquetas corporativas de la función y el mapeo."
  type        = map(string)
  nullable    = false
}
