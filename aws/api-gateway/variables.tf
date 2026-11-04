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

variable "name" {
  description = "Nombre del HTTP API."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{1,128}$", var.name))
    error_message = "Usa 1-128 caracteres: letras, números, guiones o guiones bajos."
  }
}

variable "lambda_function_arn" {
  description = "ARN de una función Lambda existente, opcionalmente calificado por versión o alias."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:(aws|aws-us-gov|aws-cn):lambda:[a-z0-9-]+:[0-9]{12}:function:[A-Za-z0-9_-]+(:[A-Za-z0-9_-]+)?$", var.lambda_function_arn))
    error_message = "Proporciona un ARN de función Lambda válido."
  }
}

variable "routes" {
  description = "Rutas del API que usan la función Lambda y la autorización seleccionada."
  type        = set(string)
  default     = ["$default"]
  nullable    = false

  validation {
    condition = length(var.routes) > 0 && alltrue([
      for route in var.routes : can(regex("^(\\$default|(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS|ANY) /[^ ]*)$", route))
    ])
    error_message = "Proporciona rutas como GET /items, ANY /{proxy+} o $default."
  }
}

variable "authorization_type" {
  description = "AWS_IAM por defecto o JWT. Este baseline no permite rutas sin autenticación."
  type        = string
  default     = "AWS_IAM"
  nullable    = false

  validation {
    condition     = contains(["AWS_IAM", "JWT"], var.authorization_type)
    error_message = "El baseline admite AWS_IAM o JWT; no admite NONE."
  }
}

variable "jwt" {
  description = "Emisor HTTPS y audiencias del proveedor de identidad; requerido solo para autorización JWT."
  type = object({
    issuer   = string
    audience = set(string)
  })
  default = null

  validation {
    condition = var.authorization_type == "JWT" ? (
      var.jwt == null ? false : (
        can(regex("^https://[^ ]+$", var.jwt.issuer)) && length(var.jwt.audience) > 0 &&
        alltrue([for audience in var.jwt.audience : length(trimspace(audience)) > 0])
      )
    ) : var.jwt == null
    error_message = "JWT requiere emisor HTTPS y audiencias no vacías; con AWS_IAM, jwt debe ser null."
  }
}

variable "authorization_scopes" {
  description = "Scopes exigidos a los tokens JWT; una lista vacía solo valida emisor y audiencia."
  type        = set(string)
  default     = []
  nullable    = false

  validation {
    condition = (length(var.authorization_scopes) == 0 || var.authorization_type == "JWT") && alltrue([
      for scope in var.authorization_scopes : length(trimspace(scope)) > 0
    ])
    error_message = "Los scopes solo aplican a JWT y deben ser no vacíos."
  }
}

variable "stage_name" {
  description = "Stage del API; $default expone las rutas sin prefijo de stage."
  type        = string
  default     = "$default"
  nullable    = false

  validation {
    condition     = var.stage_name == "$default" || can(regex("^[A-Za-z0-9_-]{1,128}$", var.stage_name))
    error_message = "Stage inválido; usa $default o un nombre de hasta 128 caracteres."
  }
}

variable "throttling_rate_limit" {
  description = "Solicitudes por segundo; debe respetar las cuotas regionales de la cuenta."
  type        = number
  default     = 100
  nullable    = false

  validation {
    condition     = var.throttling_rate_limit > 0
    error_message = "El límite de solicitudes debe ser positivo."
  }
}

variable "throttling_burst_limit" {
  description = "Capacidad de ráfaga; debe respetar las cuotas regionales de la cuenta."
  type        = number
  default     = 200
  nullable    = false

  validation {
    condition     = var.throttling_burst_limit >= 1 && floor(var.throttling_burst_limit) == var.throttling_burst_limit
    error_message = "La ráfaga debe ser un entero positivo."
  }
}

variable "access_log_retention_days" {
  description = "Retención de logs de acceso en CloudWatch."
  type        = number
  default     = 90
  nullable    = false

  validation {
    condition     = contains([30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.access_log_retention_days)
    error_message = "Selecciona una retención de CloudWatch soportada de al menos 30 días."
  }
}

variable "log_kms_key_arn" {
  description = "ARN de una clave KMS existente que autorice al servicio regional CloudWatch Logs."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:(aws|aws-us-gov|aws-cn):kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$", var.log_kms_key_arn))
    error_message = "Proporciona el ARN de una clave KMS; no un alias ni un identificador aislado."
  }
}
