variable "name" {
  description = "Nombre del repositorio de imágenes."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]+(?:[._-][a-z0-9]+)*(?:/[a-z0-9]+(?:[._-][a-z0-9]+)*)*$", var.name)) && length(var.name) >= 2 && length(var.name) <= 256
    error_message = "Usa minúsculas, dígitos, puntos, guiones o barras, entre 2 y 256 caracteres."
  }
}

variable "kms_key_arn" {
  description = "Clave KMS para cifrar las imágenes. Con null se usa AES-256 gestionado por ECR."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:aws[a-z0-9-]*:kms:[a-z0-9-]+:[0-9]{12}:key/", var.kms_key_arn))
    error_message = "Indica el ARN de una clave KMS con key/, sin alias."
  }
}

variable "keep_tagged_images" {
  description = "Imágenes etiquetadas que se conservan. Las más antiguas expiran."
  type        = number
  default     = 30
  nullable    = false

  validation {
    condition     = var.keep_tagged_images >= 1 && var.keep_tagged_images <= 1000
    error_message = "Conserva entre 1 y 1000 imágenes."
  }
}

variable "untagged_expiration_days" {
  description = "Días tras los cuales expiran las imágenes sin etiqueta."
  type        = number
  default     = 7
  nullable    = false

  validation {
    condition     = var.untagged_expiration_days >= 1
    error_message = "Usa al menos un día."
  }
}

variable "pull_principal_arns" {
  description = "Cuentas o roles de otras cuentas que pueden descargar imágenes. La cuenta propietaria ya tiene acceso por IAM."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "force_delete" {
  description = "Permite borrar el repositorio aunque contenga imágenes."
  type        = bool
  default     = false
  nullable    = false
}

variable "tags" {
  description = "Etiquetas del repositorio."
  type        = map(string)
  default     = {}
  nullable    = false
}
