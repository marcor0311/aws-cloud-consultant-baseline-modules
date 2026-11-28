output "key_arn" {
  description = "ARN de la clave para cifrado y políticas IAM."
  value       = aws_kms_key.this.arn
}

output "key_id" {
  description = "Identificador de la clave."
  value       = aws_kms_key.this.key_id
}

output "alias_name" {
  description = "Nombre del alias asociado a la clave."
  value       = aws_kms_alias.this.name
}
