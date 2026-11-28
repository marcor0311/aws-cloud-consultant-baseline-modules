# VPC aislada

Solo subredes privadas, sin Internet Gateway ni NAT. El acceso a S3 y DynamoDB usa endpoints de puerta de enlace. Otros servicios AWS necesitan endpoints de interfaz que el consumidor agrega con `private_route_table_ids` y `vpc_id`.

Para validar, ejecuta `terraform init -backend=false -lockfile=readonly` y `terraform validate`. Usa `terraform.tfvars.example` para identificar los valores del consumidor.
