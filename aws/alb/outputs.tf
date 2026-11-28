output "load_balancer_arn" {
  description = "ARN del balanceador, por ejemplo para asociar WAF."
  value       = aws_lb.this.arn
}

output "dns_name" {
  description = "Nombre DNS para un registro alias de Route 53."
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "Zona alojada del balanceador para registros alias."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "Grupo de destinos para registrar servicios ECS, pods o instancias."
  value       = aws_lb_target_group.this.arn
}

output "security_group_id" {
  description = "Grupo principal del balanceador. Los destinos deben aceptar tráfico desde este grupo."
  value       = local.security_group_ids[0]
}

output "https_listener_arn" {
  description = "Listener HTTPS para agregar reglas por ruta o host."
  value       = aws_lb_listener.https.arn
}
