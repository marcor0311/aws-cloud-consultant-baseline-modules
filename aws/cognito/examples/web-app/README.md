# Usuarios de una aplicación web

Grupo de usuarios con inicio de sesión por correo y un cliente público con flujo de código y PKCE. Para proteger una API del módulo [API Gateway](../../../api-gateway/), configura un autorizador JWT con `issuer_url` como emisor y `client_id` como audiencia.

Para validar, ejecuta `terraform init -backend=false -lockfile=readonly` y `terraform validate`. Usa `terraform.tfvars.example` para identificar los valores del consumidor.
