output "role_arn" {
  description = "ARN del rol de ejecución con la política incluida."
  value       = aws_iam_role.execution.arn
  depends_on  = [aws_iam_role_policy.execution]
}

output "role_name" {
  description = "Nombre del rol IAM."
  value       = aws_iam_role.execution.name
}
