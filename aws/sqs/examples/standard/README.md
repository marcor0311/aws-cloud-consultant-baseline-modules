# SQS Standard con un productor S3

El consumidor debe proporcionar el ARN exacto del bucket y su cuenta, en la misma región que la cola. Después de crear la cola y su política, configura la notificación en el bucket usando `queue_arn`. Ambas colas usan SSE-SQS.

Para validar, ejecuta `terraform init -backend=false -lockfile=readonly` y `terraform validate`. Usa `terraform.tfvars.example` para identificar los valores del consumidor.
