# Fan-out de SNS a varias colas SQS

Un evento publicado en el tópico llega a cada cola suscrita del módulo [SQS](../../../sqs/), y cada consumidor procesa a su ritmo. La política de cada cola debe permitir `sqs:SendMessage` a `sns.amazonaws.com` con `aws:SourceArn` igual a `topic_arn`.

Para validar, ejecuta `terraform init -backend=false -lockfile=readonly` y `terraform validate`. Usa `terraform.tfvars.example` para identificar los valores del consumidor.
