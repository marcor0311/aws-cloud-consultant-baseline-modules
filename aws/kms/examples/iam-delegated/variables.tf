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
