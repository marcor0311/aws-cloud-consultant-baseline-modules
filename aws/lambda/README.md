# Baseline de Lambda

Crea una función Lambda x86_64 a partir de un ZIP local y conecta, si se configura, una cola SQS Standard. El perfil `sqs-standard` ejecuta la función que procesa los eventos de objetos del PoC. El consumidor proporciona el paquete, el rol y el grupo de logs.

| Perfil | Comportamiento | Ejemplo |
| --- | --- | --- |
| `zip` | Función con invocación autorizada por IAM | [ZIP](examples/zip/) |
| `sqs-standard` | Función con un mapeo SQS y respuesta de fallos parciales | [SQS Standard](examples/sqs-standard/) |

## Contrato

| Entrada | Uso |
| --- | --- |
| `function_name`, `handler`, `runtime` | Nombre de la función y punto de entrada de un runtime vigente compatible con ZIP y x86_64. |
| `filename`, `source_code_hash` | Ruta al ZIP. El SHA-256 Base64 opcional se calcula a partir del archivo cuando se omite. El mismo ZIP debe estar disponible al planificar y aplicar. |
| `role_arn`, `log_group_name` | Rol de ejecución con confianza para Lambda y grupo CloudWatch Logs preaprovisionado en la región. |
| `environment_variables` | Mapa de configuración no secreta. Los valores pueden aparecer en el estado de Terraform. |
| `memory_size`, `timeout` | Memoria inicial de 128 MiB y tiempo máximo de 30 segundos, ajustables por el consumidor. |
| `reserved_concurrent_executions` | Cuota reservada opcional. El valor predeterminado utiliza la concurrencia sin reserva de la cuenta. |
| `sqs_event_source` | Objeto opcional con `queue_arn`, `visibility_timeout_seconds`, `batch_size` (10) y `maximum_batching_window_in_seconds` (0). La visibilidad real de la cola debe cubrir seis veces el timeout más la ventana. |
| `tags` | Etiquetas de la función y del mapeo. |

Salidas `function_name`, `function_arn` y `event_source_mapping_uuid` (null en el perfil ZIP).

El rol debe poder crear streams y escribir eventos en el grupo. Para SQS también requiere `sqs:ReceiveMessage`, `sqs:DeleteMessage` y `sqs:GetQueueAttributes` sobre la cola, más `kms:Decrypt` sobre su clave si usa una clave KMS. Agrega los permisos de aplicación sobre S3 y DynamoDB al rol del consumidor. En un único plan Terraform, haz que el ARN de rol dependa de las políticas necesarias antes de crear el mapeo.

El mapeo habilita `ReportBatchItemFailures`. El handler devuelve `batchItemFailures` con el ID de cada mensaje que falló. SQS reintenta los mensajes fallidos y aplica la política de redrive de la cola. El handler debe tolerar duplicados y procesar cada evento de forma idempotente. El baseline cubre una cola Standard en la misma región y deja la política de redrive en SQS. [Errores parciales](https://docs.aws.amazon.com/lambda/latest/dg/services-sqs-errorhandling.html) · [Configuración de SQS](https://docs.aws.amazon.com/lambda/latest/dg/services-sqs-configure.html)

El módulo crea la función sin URL pública ni permisos de invocación externos. La función envía logs de texto al grupo indicado. Gestiona retención, políticas de CloudWatch y límites operativos como parte del consumidor.

## Verificación

`scripts/validate.sh lambda` ejecuta pruebas con el proveedor simulado y valida ambos ejemplos. Consulta la [especificación de alta](change-spec.md) y el [registro de auditoría](audit-record.yaml).
