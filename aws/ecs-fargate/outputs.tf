output "cluster_arn" {
  description = "ARN del clúster ECS."
  value       = aws_ecs_cluster.this.arn
}

output "service_name" {
  description = "Nombre del servicio para despliegues y autoescalado."
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "Revisión de la definición de tarea desplegada."
  value       = aws_ecs_task_definition.this.arn
}

output "task_role_arn" {
  description = "Rol de la aplicación para políticas de recursos, por ejemplo de un bucket o una cola."
  value       = aws_iam_role.task.arn
}

output "security_group_id" {
  description = "Grupo principal de las tareas, para autorizar su acceso a RDS u otros servicios."
  value       = local.security_group_ids[0]
}

output "log_group_name" {
  description = "Grupo de CloudWatch Logs del contenedor."
  value       = aws_cloudwatch_log_group.this.name
}
