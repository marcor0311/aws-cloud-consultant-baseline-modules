# Amazon SQS Standard y DLQ

Crea una cola Standard con una cola de errores Standard. El productor y el consumidor se configuran en el proyecto que llama al módulo. Ambas colas usan cifrado en reposo y políticas que exigen TLS a los clientes. La DLQ acepta mensajes redirigidos desde la cola principal.

| Perfil | Configuración | Ejemplo |
| --- | --- | --- |
| `standard` | SSE-SQS y permiso de publicación para un bucket concreto. Adecuado para notificaciones directas de S3. | [Terraform](examples/standard/) |
| `standard-kms` | Clave KMS gestionada por el consumidor usada en ambas colas. | [Terraform](examples/standard-kms/) |

| Entrada | Tipo | Valor predeterminado |
| --- | --- | --- |
| `name` | `string` | Obligatoria. Hasta 76 caracteres para reservar el sufijo `-dlq`. |
| `visibility_timeout_seconds` | `number` | `60` segundos |
| `max_receive_count` | `number` | `5` recepciones |
| `kms_key_arn` | `string` | `null`, que activa SSE-SQS |
| `s3_source` | `object({ bucket_arn = string, account_id = string })` | `null`. El proyecto habilita el permiso de un bucket exacto. |
| `tags` | `map(string)` | `{}` |

`queue_arn` y `queue_url` quedan disponibles después de adjuntar las políticas de publicación y de redrive. Usa `dead_letter_queue_arn` y `dead_letter_queue_url` para supervisar la DLQ y definir permisos de redrive. Ambas colas admiten solicitudes de espera larga de 20 segundos. La cola principal retiene mensajes cuatro días y la DLQ catorce.

Para conectar S3, crea la notificación en el proyecto consumidor, con bucket y cola en la misma región y el ARN de la cola como destino. Con una clave gestionada por el cliente, la política de la clave debe autorizar a S3 a generar claves de datos y descifrar. El consumidor que lea de la cola cifrada necesita `kms:Decrypt`.

SQS Standard entrega al menos una vez y el orden puede variar. Haz idempotente el consumidor y configura la visibilidad para su tiempo de ejecución. Para Lambda, AWS recomienda al menos seis veces el timeout de la función más su ventana de agrupación. Las notificaciones directas de S3 admiten colas Standard. El borrado o reemplazo de una cola elimina los mensajes pendientes de esa cola, por lo que una migración debe drenarla primero.

[Especificación del cambio](change-spec.md)
