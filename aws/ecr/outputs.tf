output "repository_arn" {
  description = "ARN del repositorio para políticas IAM de publicación y descarga."
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "URL para docker push y para la imagen de una tarea ECS."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_name" {
  description = "Nombre del repositorio."
  value       = aws_ecr_repository.this.name
}
