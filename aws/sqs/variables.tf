variable "name" {
  description = "Nombre de la cola Standard. El módulo añade -dlq para la cola de errores."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{1,76}$", var.name))
    error_message = "Usa de 1 a 76 letras, dígitos, guiones o guiones bajos para reservar espacio al sufijo -dlq."
  }
}

variable "visibility_timeout_seconds" {
  description = "Segundos que permanece invisible un mensaje recibido. Ajustar según el tiempo de procesamiento del consumidor."
  type        = number
  default     = 60
  nullable    = false

  validation {
    condition     = floor(var.visibility_timeout_seconds) == var.visibility_timeout_seconds && var.visibility_timeout_seconds >= 1 && var.visibility_timeout_seconds <= 43200
    error_message = "La visibilidad debe ser un número entero entre 1 y 43200 segundos."
  }
}

variable "max_receive_count" {
  description = "Recepciones admitidas antes de enviar el mensaje a la DLQ."
  type        = number
  default     = 5
  nullable    = false

  validation {
    condition     = floor(var.max_receive_count) == var.max_receive_count && var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "El límite de recepciones debe ser un entero entre 1 y 1000."
  }
}

variable "kms_key_arn" {
  description = "ARN de una clave KMS simétrica de la región para ambas colas. Con null se aplica SSE-SQS."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:aws[a-z0-9-]*:kms:[a-z0-9-]+:[0-9]{12}:key/([0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}|mrk-[0-9a-f]{32})$", var.kms_key_arn))
    error_message = "Indica el ARN de una clave KMS. Usa key/ con su identificador, sin alias."
  }
}

variable "s3_source" {
  description = "Permite publicar eventos de un bucket S3 exacto y de su cuenta propietaria."
  type = object({
    bucket_arn = string
    account_id = string
  })
  default = null

  validation {
    condition = var.s3_source == null ? true : (
      can(regex("^arn:aws[a-z0-9-]*:s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.s3_source.bucket_arn)) &&
      can(regex("^[0-9]{12}$", var.s3_source.account_id))
    )
    error_message = "Especifica el ARN de un bucket S3 exacto y los 12 dígitos de su cuenta AWS."
  }
}

variable "tags" {
  description = "Etiquetas de ambas colas."
  type        = map(string)
  default     = {}
  nullable    = false
}
