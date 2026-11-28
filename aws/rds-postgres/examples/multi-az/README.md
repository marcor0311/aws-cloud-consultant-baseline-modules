# PostgreSQL Multi-AZ

Instancia `db.m7g.large` con réplica en espera y conmutación automática para producción. Duplica el costo de cómputo y almacenamiento frente a una zona.

Para validar, ejecuta `terraform init -backend=false -lockfile=readonly` y `terraform validate`. Usa `terraform.tfvars.example` para identificar los valores del consumidor.
