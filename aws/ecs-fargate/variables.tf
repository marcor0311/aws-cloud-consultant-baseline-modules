variable "name" {
  description = "Nombre del servicio. Se usa en el clúster, la tarea, los roles y los logs."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,30}$", var.name))
    error_message = "Usa de 2 a 31 minúsculas, dígitos o guiones."
  }
}

variable "image" {
  description = "Imagen del contenedor con etiqueta o digest, por ejemplo la repository_url del módulo ECR."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("[:@]", var.image)) && !endswith(var.image, ":latest")
    error_message = "Indica una etiqueta concreta o un digest; latest no permite despliegues reproducibles."
  }
}

variable "container_port" {
  description = "Puerto en el que escucha el contenedor."
  type        = number
  default     = 8080
  nullable    = false
}

variable "cpu" {
  description = "Unidades de CPU de la tarea Fargate."
  type        = number
  default     = 256
  nullable    = false

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "Usa 256, 512, 1024, 2048 o 4096."
  }
}

variable "memory" {
  description = "Memoria de la tarea en MiB, compatible con la CPU elegida."
  type        = number
  default     = 512
  nullable    = false
}

variable "desired_count" {
  description = "Tareas en ejecución. Usa dos o más en producción para tolerar la caída de una zona."
  type        = number
  default     = 2
  nullable    = false

  validation {
    condition     = var.desired_count >= 0 && var.desired_count <= 100
    error_message = "Usa entre 0 y 100 tareas."
  }
}

variable "vpc_id" {
  description = "VPC del servicio."
  type        = string
  nullable    = false
}

variable "subnet_ids" {
  description = "Subredes privadas para las tareas."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "Indica al menos una subred."
  }
}

variable "security_group_ids" {
  description = "Grupos existentes de las tareas. Con null el módulo crea uno con salida HTTPS y entrada desde source_security_group_id."
  type        = list(string)
  default     = null
}

variable "source_security_group_id" {
  description = "Grupo autorizado a llamar al contenedor, normalmente el del ALB."
  type        = string
  default     = null
}

variable "egress_cidr_blocks" {
  description = "Destinos HTTPS de las tareas. Con null solo la VPC, donde viven los endpoints de interfaz de ECR, Logs y Secrets Manager. Con NAT, indica 0.0.0.0/0 de forma explícita."
  type        = list(string)
  default     = null

  validation {
    condition     = var.egress_cidr_blocks == null || alltrue([for block in coalesce(var.egress_cidr_blocks, []) : can(cidrnetmask(block))])
    error_message = "Indica bloques IPv4 válidos."
  }
}

variable "target_group_arn" {
  description = "Grupo de destinos del ALB. Con null el servicio no se registra en un balanceador."
  type        = string
  default     = null
}

variable "environment" {
  description = "Variables de entorno no sensibles."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "secrets" {
  description = "Variables sensibles como nombre => ARN de Secrets Manager o SSM. El rol de ejecución recibe permiso de lectura sobre esos ARN."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "task_role_policy_json" {
  description = "Política IAM que necesita la aplicación para llamar a otros servicios AWS. Con null el rol de la tarea no tiene permisos."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Días de retención de los logs del contenedor."
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
