# PostgreSQL en una zona

Instancia `db.t4g.micro` para desarrollo y pruebas. El usuario maestro se guarda en Secrets Manager; pasa `master_user_secret_arn` al servicio como secreto. Solo los grupos de `client_security_group_ids` llegan al puerto 5432.

Para validar, ejecuta `terraform init -backend=false -lockfile=readonly` y `terraform validate`. Usa `terraform.tfvars.example` para identificar los valores del consumidor.
