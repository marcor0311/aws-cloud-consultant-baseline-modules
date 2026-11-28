# Bus de dominio con una regla hacia SQS

Los productores publican con `PutEvents` en el bus. La regla `order-created` envía los pedidos a una cola del módulo [SQS](../../../sqs/), cuya política debe permitir `sqs:SendMessage` a `events.amazonaws.com` con el ARN de la regla como origen. La DLQ necesita el mismo permiso.

Para validar, ejecuta `terraform init -backend=false -lockfile=readonly` y `terraform validate`. Usa `terraform.tfvars.example` para identificar los valores del consumidor.
