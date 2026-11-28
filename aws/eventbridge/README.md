# Amazon EventBridge

Crea un bus personalizado, reglas que filtran eventos con patrones JSON y un destino por regla: cola SQS, tópico SNS o función Lambda. Cada destino reintenta hasta una hora y luego envía el evento a una DLQ obligatoria. El bus archiva los eventos siete días para reproducirlos.

| Perfil | Configuración | Ejemplo |
| --- | --- | --- |
| `custom-bus` | Bus de dominio con una regla hacia SQS. | [Terraform](examples/custom-bus/) |

| Entrada | Tipo | Valor predeterminado |
| --- | --- | --- |
| `bus_name` | `string` | Obligatoria. Distinto de `default`. |
| `dead_letter_queue_arn` | `string` | Obligatoria |
| `rules` | `map(object({ description, event_pattern, target_type, target_arn }))` | `{}` |
| `maximum_event_age_seconds` | `number` | `3600` |
| `archive_retention_days` | `number` | `7`; `0` lo desactiva |
| `tags` | `map(string)` | `{}` |

Salidas: `bus_name`, `bus_arn` y `rule_arns`.

Las colas y tópicos destino, y la DLQ, deben autorizar a `events.amazonaws.com` con el ARN de la regla como origen. Para Lambda el módulo crea ese permiso. Los productores necesitan `events:PutEvents` sobre `bus_arn`.

[Especificación del cambio](change-spec.md)
