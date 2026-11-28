variable "name" {
  description = "Nombre de la máquina de estados, su rol y su grupo de logs."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{1,52}$", var.name))
    error_message = "Usa hasta 52 letras, dígitos, guiones o guiones bajos."
  }
}

variable "definition" {
  description = "Definición en Amazon States Language como JSON."
  type        = string
  nullable    = false

  validation {
    condition     = can(jsondecode(var.definition).StartAt) && can(jsondecode(var.definition).States)
    error_message = "La definición debe ser JSON con StartAt y States."
  }
}

variable "lambda_function_arns" {
  description = "Funciones que el flujo puede invocar. El rol recibe lambda:InvokeFunction solo sobre ellas."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "additional_policy_json" {
  description = "Permisos adicionales del flujo, por ejemplo dynamodb:PutItem o sqs:SendMessage sobre recursos concretos."
  type        = string
  default     = null
}

variable "log_level" {
  description = "Nivel de registro de ejecuciones: ERROR registra fallos, ALL registra cada transición."
  type        = string
  default     = "ERROR"
  nullable    = false

  validation {
    condition     = contains(["ALL", "ERROR", "FATAL"], var.log_level)
    error_message = "Usa ALL, ERROR o FATAL."
  }
}

variable "log_retention_days" {
  description = "Días de retención de los logs de ejecución."
  type        = number
  default     = 30
  nullable    = false
}

variable "tags" {
  description = "Etiquetas de todos los recursos."
  type        = map(string)
  default     = {}
  nullable    = false
}
