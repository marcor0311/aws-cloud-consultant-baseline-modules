output "endpoint" {
  description = "Host de conexión de la instancia."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Puerto de PostgreSQL."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Base de datos inicial."
  value       = aws_db_instance.this.db_name
}

output "master_user_secret_arn" {
  description = "Secreto de Secrets Manager con el usuario maestro, rotado por RDS. Pásalo a ECS como secreto."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "resource_id" {
  description = "Identificador para políticas rds-db:connect con autenticación IAM."
  value       = aws_db_instance.this.resource_id
}

output "security_group_id" {
  description = "Grupo principal de la base de datos."
  value       = local.security_group_ids[0]
}
