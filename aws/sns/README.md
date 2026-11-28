# Amazon SNS

Crea un tópico Standard cifrado con una clave KMS del cliente, con política que limita el acceso a la cuenta propietaria y a servicios AWS acotados por ARN de origen, y que rechaza publicaciones sin TLS. Suscribe colas SQS con entrega en bruto para el patrón fan-out.

| Perfil | Configuración | Ejemplo |
| --- | --- | --- |
| `fan-out` | Tópico con varias colas SQS suscritas. | [Terraform](examples/fan-out/) |

| Entrada | Tipo | Valor predeterminado |
| --- | --- | --- |
| `name` | `string` | Obligatoria |
| `kms_key_arn` | `string` | Obligatoria |
| `publisher_services` | `list(object({ service, source_arn }))` | `[]` |
| `sqs_subscriptions` | `map(string)` | `{}` |
| `tags` | `map(string)` | `{}` |

Salidas: `topic_arn` y `subscription_arns`.

La clave es obligatoria porque la administrada `alias/aws/sns` no deja publicar a EventBridge, CloudWatch ni S3. Su política debe permitir `kms:GenerateDataKey` y `kms:Decrypt` a esos servicios. El módulo [KMS](../kms/) la crea. Las colas suscritas cifradas con KMS también deben permitir a SNS usar su clave.

[Especificación del cambio](change-spec.md)
