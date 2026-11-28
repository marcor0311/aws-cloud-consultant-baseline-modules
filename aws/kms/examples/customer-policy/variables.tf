variable "aws_region" {
  description = "Región AWS del entorno consumidor."
  type        = string
  nullable    = false
}

variable "alias_name" {
  description = "Alias de KMS en la cuenta y región seleccionadas."
  type        = string
  nullable    = false
}

variable "aws_account_id" {
  description = "Cuenta AWS propietaria de la clave y del grupo de logs."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "Especifica los 12 dígitos de la cuenta AWS."
  }
}

variable "log_group_name" {
  description = "Nombre exacto del grupo de CloudWatch Logs que puede usar la clave."
  type        = string
  nullable    = false
}
