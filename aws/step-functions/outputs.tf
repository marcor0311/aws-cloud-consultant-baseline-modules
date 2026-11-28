output "state_machine_arn" {
  description = "ARN para StartExecution desde API Gateway, EventBridge o el SDK."
  value       = aws_sfn_state_machine.this.arn
}

output "role_arn" {
  description = "Rol del flujo, para políticas de recursos que lo autoricen."
  value       = aws_iam_role.this.arn
}

output "log_group_name" {
  description = "Grupo de logs de las ejecuciones."
  value       = aws_cloudwatch_log_group.this.name
}
