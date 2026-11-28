# Amazon SNS

Crea un tópico Standard cifrado, con política que limita el acceso a la cuenta propietaria y a servicios AWS acotados por ARN de origen, y que rechaza publicaciones sin TLS. Suscribe colas SQS con entrega en bruto para el patrón fan-out.

| Perfil | Configuración | Ejemplo |
| --- | --- | --- |
| `fan-out` | Tópico con varias colas SQS suscritas. | [Terraform](examples/fan-out/) |

| Entrada | Tipo | Valor predeterminado |
| --- | --- | --- |
| `name` | `string` | Obligatoria |
| `kms_key_arn` | `string` | `null`, que usa `alias/aws/sns` |
| `publisher_services` | `list(object({ service, source_arn }))` | `[]` |
| `sqs_subscriptions` | `map(string)` | `{}` |
| `tags` | `map(string)` | `{}` |

Salidas: `topic_arn` y `subscription_arns`.

La clave `alias/aws/sns` no permite que otros servicios AWS publiquen. Si EventBridge, CloudWatch o S3 publican en el tópico, usa una clave gestionada por el cliente cuya política les permita `kms:GenerateDataKey` y `kms:Decrypt`. Las colas suscritas cifradas con KMS también deben permitir a SNS usar su clave.

[Especificación del cambio](change-spec.md)
