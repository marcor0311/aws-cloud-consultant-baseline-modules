variable "name" {
  description = "Nombre del grupo de usuarios y prefijo de su cliente."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{1,64}$", var.name))
    error_message = "Usa hasta 64 letras, dígitos, guiones o guiones bajos."
  }
}

variable "callback_urls" {
  description = "URL HTTPS a las que vuelve el usuario tras iniciar sesión. Se permite http://localhost para desarrollo."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.callback_urls) > 0 && alltrue([for url in var.callback_urls : startswith(url, "https://") || startswith(url, "http://localhost")])
    error_message = "Indica al menos una URL HTTPS o http://localhost."
  }
}

variable "logout_urls" {
  description = "URL a las que vuelve el usuario tras cerrar sesión."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "mfa" {
  description = "Segundo factor: OPTIONAL deja que cada usuario lo active, ON lo exige."
  type        = string
  default     = "OPTIONAL"
  nullable    = false

  validation {
    condition     = contains(["OPTIONAL", "ON"], var.mfa)
    error_message = "Usa OPTIONAL u ON."
  }
}

variable "self_sign_up" {
  description = "Permite que los usuarios se registren solos. Con false solo un administrador los crea."
  type        = bool
  default     = false
  nullable    = false
}

variable "deletion_protection" {
  description = "Impide borrar el grupo de usuarios por error."
  type        = bool
  default     = true
  nullable    = false
}

variable "tags" {
  description = "Etiquetas del grupo de usuarios."
  type        = map(string)
  default     = {}
  nullable    = false
}
