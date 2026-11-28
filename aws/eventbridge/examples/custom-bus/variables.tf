variable "aws_region" {
  description = "Región AWS del entorno consumidor."
  type        = string
  nullable    = false
}

variable "bus_name" {
  description = "Nombre del bus."
  type        = string
  nullable    = false
}

variable "orders_queue_arn" {
  description = "Cola que recibe los pedidos creados."
  type        = string
  nullable    = false
}

variable "dead_letter_queue_arn" {
  description = "Cola de eventos no entregados."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Etiquetas del proyecto."
  type        = map(string)
  default     = {}
}
