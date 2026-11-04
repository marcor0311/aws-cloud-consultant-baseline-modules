variable "tags" {
  description = "Etiquetas corporativas: Project, Environment, Owner y CostCenter; admite etiquetas adicionales."
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

variable "table_name" {
  description = "Nombre de la tabla DynamoDB."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]{3,255}$", var.table_name))
    error_message = "El nombre debe tener 3-255 caracteres: letras, números, guiones, puntos o guiones bajos."
  }
}

variable "partition_key" {
  description = "Clave de partición; tipo S, N o B."
  type        = object({ name = string, type = string })
  default     = { name = "pk", type = "S" }
  nullable    = false

  validation {
    condition     = length(trimspace(var.partition_key.name)) > 0 && contains(["S", "N", "B"], var.partition_key.type)
    error_message = "La clave necesita nombre no vacío y tipo S, N o B."
  }
}

variable "sort_key" {
  description = "Clave de ordenamiento; null crea una tabla solo con clave de partición."
  type        = object({ name = string, type = string })
  default     = { name = "sk", type = "S" }

  validation {
    condition = var.sort_key == null ? true : (
      length(trimspace(var.sort_key.name)) > 0 && contains(["S", "N", "B"], var.sort_key.type) &&
      var.sort_key.name != var.partition_key.name
    )
    error_message = "La clave necesita nombre distinto de la partición y tipo S, N o B."
  }
}

variable "billing_mode" {
  description = "PAY_PER_REQUEST (on-demand) o PROVISIONED."
  type        = string
  default     = "PAY_PER_REQUEST"
  nullable    = false

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "billing_mode debe ser PAY_PER_REQUEST o PROVISIONED."
  }
}

variable "read_capacity" {
  description = "RCU para PROVISIONED; null para on-demand."
  type        = number
  default     = null

  validation {
    condition = var.billing_mode == "PROVISIONED" ? (
      var.read_capacity == null ? false : var.read_capacity >= 1 && floor(var.read_capacity) == var.read_capacity
    ) : var.read_capacity == null
    error_message = "PROVISIONED requiere RCU enteras positivas; on-demand requiere null."
  }
}

variable "write_capacity" {
  description = "WCU para PROVISIONED; null para on-demand."
  type        = number
  default     = null

  validation {
    condition = var.billing_mode == "PROVISIONED" ? (
      var.write_capacity == null ? false : var.write_capacity >= 1 && floor(var.write_capacity) == var.write_capacity
    ) : var.write_capacity == null
    error_message = "PROVISIONED requiere WCU enteras positivas; on-demand requiere null."
  }
}

variable "on_demand_max_read_request_units" {
  description = "Límite opcional de lecturas por segundo on-demand; null usa el valor del servicio."
  type        = number
  default     = null

  validation {
    condition = var.on_demand_max_read_request_units == null ? true : (
      var.billing_mode == "PAY_PER_REQUEST" && var.on_demand_max_read_request_units >= 1 &&
      floor(var.on_demand_max_read_request_units) == var.on_demand_max_read_request_units
    )
    error_message = "El límite requiere on-demand y un entero positivo."
  }
}

variable "on_demand_max_write_request_units" {
  description = "Límite opcional de escrituras por segundo on-demand; null usa el valor del servicio."
  type        = number
  default     = null

  validation {
    condition = var.on_demand_max_write_request_units == null ? true : (
      var.billing_mode == "PAY_PER_REQUEST" && var.on_demand_max_write_request_units >= 1 &&
      floor(var.on_demand_max_write_request_units) == var.on_demand_max_write_request_units
    )
    error_message = "El límite requiere on-demand y un entero positivo."
  }
}

variable "kms_key_arn" {
  description = "ARN de una clave KMS corporativa existente y accesible en la región de la tabla."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:(aws|aws-us-gov|aws-cn):kms:[a-z0-9-]+:[0-9]{12}:key/[a-zA-Z0-9-]+$", var.kms_key_arn))
    error_message = "Proporciona el ARN de una clave KMS; no un alias ni un identificador aislado."
  }
}

variable "deletion_protection_enabled" {
  description = "Protección contra borrado; deshabilitarla exige una decisión explícita y un apply previo al destroy."
  type        = bool
  default     = true
  nullable    = false
}

variable "ttl_attribute_name" {
  description = "Atributo de expiración con timestamp Unix numérico; null deshabilita TTL."
  type        = string
  default     = null

  validation {
    condition = var.ttl_attribute_name == null ? true : (
      length(trimspace(var.ttl_attribute_name)) > 0 &&
      var.ttl_attribute_name != var.partition_key.name &&
      (var.sort_key == null ? true : var.ttl_attribute_name != var.sort_key.name)
    )
    error_message = "TTL necesita un atributo no vacío distinto de las claves."
  }
}
