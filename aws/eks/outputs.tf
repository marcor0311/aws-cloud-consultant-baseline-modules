output "cluster_name" {
  description = "Nombre del clúster EKS."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN del clúster EKS."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint privado del servidor API de Kubernetes."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificado público CA en base64 para verificar el endpoint de Kubernetes."
  value       = one(aws_eks_cluster.this.certificate_authority).data
}

output "node_group_name" {
  description = "Nombre del grupo EKS de nodos administrados."
  value       = aws_eks_node_group.this.node_group_name
}

output "control_plane_log_group_arn" {
  description = "ARN del grupo de logs del plano de control."
  value       = aws_cloudwatch_log_group.control_plane.arn
}
