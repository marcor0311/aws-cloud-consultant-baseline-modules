# SQS Standard con una clave gestionada por el cliente

Proporciona el ARN de una clave simétrica en la región de ambas colas y otorga los permisos KMS requeridos por los productores y consumidores. Para conectar S3, proporciona `s3_source` al módulo, registra la notificación del bucket y configura la política de clave para el principal de servicio S3.

Para validar, ejecuta `terraform init -backend=false -lockfile=readonly` y `terraform validate`. Usa `terraform.tfvars.example` para identificar los valores del consumidor.
