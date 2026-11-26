variable "name" {
  description = "Nombre del clúster. Se usa también como prefijo para el grupo de nodos y sus logs."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,38}[a-z0-9]$", var.name))
    error_message = "Usa de 3 a 40 caracteres en minúscula, números y guiones para el nombre."
  }
}

variable "kubernetes_version" {
  description = "Versión minor con soporte estándar de EKS en la región de la carga, en formato 1.x."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^1\\.[0-9]{2,3}$", var.kubernetes_version))
    error_message = "Indica la versión minor en formato 1.x, sin versión patch."
  }
}

variable "vpc_id" {
  description = "VPC existente que contiene las subredes de EKS."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^vpc-([a-f0-9]{8}|[a-f0-9]{17})$", var.vpc_id))
    error_message = "Proporciona un identificador de VPC válido."
  }
}

variable "private_subnet_ids" {
  description = "Subredes privadas de la VPC en dos o más zonas de disponibilidad."
  type        = set(string)
  nullable    = false

  validation {
    condition = length(var.private_subnet_ids) >= 2 && alltrue([
      for subnet_id in var.private_subnet_ids : can(regex("^subnet-([a-f0-9]{8}|[a-f0-9]{17})$", subnet_id))
    ])
    error_message = "Proporciona al menos dos IDs distintos de subredes privadas."
  }
}

variable "iam_role_arns" {
  description = "Roles IAM existentes y distintos para el clúster, los nodos y el administrador de Kubernetes."
  type = object({
    cluster       = string
    nodes         = string
    administrator = string
  })
  nullable = false

  validation {
    condition = length(toset(values(var.iam_role_arns))) == 3 && alltrue([
      for arn in values(var.iam_role_arns) : can(regex("^arn:aws(-[a-z0-9-]+)?:iam::[0-9]{12}:role/[A-Za-z0-9_+=,.@/-]+$", arn))
    ])
    error_message = "Indica tres ARNs distintos de roles IAM."
  }
}

variable "kms_key_arns" {
  description = "Claves KMS existentes para datos de Kubernetes y logs de CloudWatch."
  type = object({
    secrets = string
    logs    = string
  })
  nullable = false

  validation {
    condition = alltrue([
      for arn in values(var.kms_key_arns) : can(regex("^arn:aws(-[a-z0-9-]+)?:kms:[a-z0-9-]+:[0-9]{12}:key/[A-Za-z0-9-]+$", arn))
    ])
    error_message = "Indica ARNs de claves KMS, sin alias."
  }
}

variable "node_group" {
  description = "Capacidad On-Demand x86-64 del grupo administrado y tamaño de sus discos raíz gp3."
  type = object({
    instance_type = optional(string, "m6i.large")
    min_size      = optional(number, 2)
    desired_size  = optional(number, 2)
    max_size      = optional(number, 4)
    disk_size_gib = optional(number, 40)
  })
  default  = {}
  nullable = false

  validation {
    condition = (
      var.node_group.min_size >= 2 &&
      var.node_group.min_size <= var.node_group.desired_size &&
      var.node_group.desired_size <= var.node_group.max_size &&
      alltrue([for size in [var.node_group.min_size, var.node_group.desired_size, var.node_group.max_size] : size == floor(size)])
    )
    error_message = "Los tamaños deben ser enteros y cumplir 2 <= mínimo <= deseado <= máximo."
  }

  validation {
    condition = (
      can(regex("^[a-z0-9-]+\\.[a-z0-9-]+$", var.node_group.instance_type)) &&
      var.node_group.disk_size_gib == floor(var.node_group.disk_size_gib) &&
      var.node_group.disk_size_gib >= 20 && var.node_group.disk_size_gib <= 16384
    )
    error_message = "Indica un tipo EC2 y un disco gp3 de 20 a 16384 GiB enteros."
  }
}

variable "log_retention_days" {
  description = "Retención de logs del plano de control."
  type        = number
  default     = 90
  nullable    = false

  validation {
    condition     = contains([30, 60, 90, 120, 150, 180, 365], var.log_retention_days)
    error_message = "La retención debe ser 30, 60, 90, 120, 150, 180 o 365 días."
  }
}

variable "deletion_protection_enabled" {
  description = "Activa la protección contra eliminación del clúster."
  type        = bool
  default     = true
  nullable    = false
}

variable "tags" {
  description = "Etiquetas corporativas Project, Environment, Owner y CostCenter."
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
