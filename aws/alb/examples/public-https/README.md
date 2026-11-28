# ALB público con HTTPS

Usa las subredes públicas del módulo [VPC](../../../vpc/) y un certificado de ACM emitido para el dominio. El puerto 80 redirige a HTTPS. Registra los destinos con `target_group_arn` y permite en su grupo de seguridad el tráfico desde `security_group_id`.

Para validar, ejecuta `terraform init -backend=false -lockfile=readonly` y `terraform validate`. Usa `terraform.tfvars.example` para identificar los valores del consumidor.
