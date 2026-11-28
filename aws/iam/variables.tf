variable "role_name" {
  description = "Nombre único del rol en la cuenta."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_+=,.@-]{1,64}$", var.role_name))
    error_message = "role_name debe ser un nombre IAM de 1 a 64 caracteres."
  }
}

variable "queue_arns" {
  description = "ARN de cada cola SQS que Lambda puede consumir."
  type        = set(string)
  nullable    = false

  validation {
    condition = length(var.queue_arns) > 0 && alltrue([
      for arn in var.queue_arns : can(regex("^arn:aws:sqs:[a-z0-9-]+:[0-9]{12}:[A-Za-z0-9_-]+(\\.fifo)?$", arn))
    ])
    error_message = "queue_arns requiere al menos un ARN exacto de una cola SQS."
  }
}

variable "log_group_arns" {
  description = "ARN de los grupos CloudWatch Logs existentes. Se acepta el sufijo :* devuelto por AWS."
  type        = set(string)
  nullable    = false

  validation {
    condition = length(var.log_group_arns) > 0 && alltrue([
      for arn in var.log_group_arns : can(regex("^arn:aws:logs:[a-z0-9-]+:[0-9]{12}:log-group:[A-Za-z0-9_./#-]+(:\\*)?$", arn))
    ])
    error_message = "log_group_arns requiere al menos un ARN de grupo de logs exacto, con sufijo opcional :*."
  }
}

variable "dynamodb_table_arns" {
  description = "ARN de las tablas DynamoDB donde Lambda puede escribir con PutItem."
  type        = set(string)
  nullable    = false

  validation {
    condition = length(var.dynamodb_table_arns) > 0 && alltrue([
      for arn in var.dynamodb_table_arns : can(regex("^arn:aws:dynamodb:[a-z0-9-]+:[0-9]{12}:table/[A-Za-z0-9_.-]+$", arn))
    ])
    error_message = "dynamodb_table_arns requiere al menos un ARN exacto de una tabla DynamoDB."
  }
}

variable "s3_object_arns" {
  description = "ARN opcionales de objetos S3 que Lambda puede leer. Se permiten prefijos concretos terminados en /*."
  type        = set(string)
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for arn in var.s3_object_arns : can(regex("^arn:aws:s3:::[a-z0-9][a-z0-9.-]+[a-z0-9]/([^*?$]+|[^*?$]+/\\*)$", arn))
    ])
    error_message = "s3_object_arns admite objetos exactos y prefijos concretos terminados en /*."
  }
}

variable "kms_key_arns" {
  description = "ARN opcionales de claves KMS que Lambda puede usar para descifrar datos."
  type        = set(string)
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for arn in var.kms_key_arns : can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[A-Za-z0-9-]+$", arn))
    ])
    error_message = "kms_key_arns admite ARN exactos de claves KMS, sin alias ni comodines."
  }
}

variable "tags" {
  description = "Etiquetas que aporta el consumidor."
  type        = map(string)
  nullable    = false
}
