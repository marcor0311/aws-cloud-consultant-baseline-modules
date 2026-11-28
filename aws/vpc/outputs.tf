output "vpc_id" {
  description = "Identificador de la VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "Bloque IPv4 de la VPC."
  value       = aws_vpc.this.cidr_block
}

output "private_subnet_ids" {
  description = "Subredes privadas, una por zona, para cómputo y datos."
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Subredes públicas para balanceadores y NAT. Vacía en una VPC aislada."
  value       = aws_subnet.public[*].id
}

output "private_route_table_ids" {
  description = "Tablas de rutas privadas para endpoints adicionales."
  value       = aws_route_table.private[*].id
}

output "flow_log_group_name" {
  description = "Grupo de CloudWatch Logs con el tráfico de la VPC."
  value       = aws_cloudwatch_log_group.flow_logs.name
}
