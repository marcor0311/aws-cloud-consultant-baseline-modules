# Repositorio ECR privado

Repositorio con etiquetas inmutables, escaneo al publicar y expiración automática. Publica con `docker push` en `repository_url` y usa esa URL con una etiqueta concreta en la tarea ECS.

Para validar, ejecuta `terraform init -backend=false -lockfile=readonly` y `terraform validate`. Usa `terraform.tfvars.example` para identificar los valores del consumidor.
