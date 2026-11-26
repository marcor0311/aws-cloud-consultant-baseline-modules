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

variable "origin_domain_name" {
  description = "Endpoint REST regional del bucket S3 existente."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*\\.s3\\.[a-z0-9-]+\\.amazonaws\\.com$", var.origin_domain_name)) && !strcontains(var.origin_domain_name, "s3-website")
    error_message = "Usa un endpoint REST regional de S3 y excluye endpoints de website."
  }
}
variable "origin_bucket_arn" {
  description = "ARN del mismo bucket S3, para generar la declaración de acceso."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^arn:aws:s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.origin_bucket_arn))
    error_message = "Indica el ARN de un bucket S3 de la partición comercial."
  }
}
variable "web_acl_arn" {
  description = "ARN de una ACL WAFv2 global existente para CloudFront."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^arn:aws:wafv2:us-east-1:[0-9]{12}:global/webacl/[^/]+/[^/]+$", var.web_acl_arn))
    error_message = "Usa una ACL WAFv2 de ámbito CLOUDFRONT en us-east-1."
  }
}
variable "logging_bucket_domain" {
  description = "Dominio de un bucket existente compatible con los logs estándar legacy."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*\\.s3\\.amazonaws\\.com$", var.logging_bucket_domain))
    error_message = "Usa el dominio del bucket de logs con sufijo .s3.amazonaws.com."
  }
}
variable "price_class" {
  description = "Cobertura geográfica de puntos de presencia."
  type        = string
  default     = "PriceClass_100"
  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "Selecciona una clase de precio de CloudFront válida."
  }
}
