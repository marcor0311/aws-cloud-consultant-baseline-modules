variable "name" {
  description = "Nombre del tópico Standard."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{1,256}$", var.name))
    error_message = "Usa hasta 256 letras, dígitos, guiones o guiones bajos."
  }
}

variable "kms_key_arn" {
  description = "Clave KMS gestionada por el cliente. Su política debe permitir a los servicios publicadores y suscriptores usarla."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:aws[a-z0-9-]*:kms:[a-z0-9-]+:[0-9]{12}:key/", var.kms_key_arn))
    error_message = "Indica el ARN de una clave KMS con key/, sin alias."
  }
}

variable "publisher_services" {
  description = "Servicios AWS que pueden publicar, cada uno limitado al ARN de origen indicado. Por ejemplo events.amazonaws.com con el ARN de una regla."
  type = list(object({
    service    = string
    source_arn = string
  }))
  default  = []
  nullable = false

  validation {
    condition     = alltrue([for item in var.publisher_services : endswith(item.service, ".amazonaws.com") && startswith(item.source_arn, "arn:")])
    error_message = "Cada publicador necesita un principal de servicio *.amazonaws.com y un ARN de origen."
  }
}

variable "sqs_subscriptions" {
  description = "Colas SQS suscritas con entrega en bruto, como nombre => ARN. La política de cada cola debe permitir sns.amazonaws.com con este tópico como origen."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "tags" {
  description = "Etiquetas del tópico."
  type        = map(string)
  default     = {}
  nullable    = false
}
