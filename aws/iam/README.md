# IAM para ejecución de Lambda

Crea un rol de ejecución y una política inline para un consumidor SQS que escribe resultados en DynamoDB y utiliza un grupo de CloudWatch Logs precreado. Lambda es el único principal de confianza del rol. El módulo admite la partición comercial `aws`.

| Entrada | Alcance |
| --- | --- |
| `role_name`, `tags` | Nombre IAM único por cuenta y etiquetas del consumidor. |
| `queue_arns` | Colas fuente que Lambda puede consumir con `ReceiveMessage`, `DeleteMessage` y `GetQueueAttributes`. SQS gestiona la transferencia a la DLQ. |
| `log_group_arns` | Grupos existentes, con sufijo opcional `:*`. Autoriza crear y escribir streams de esos grupos. |
| `dynamodb_table_arns` | Tablas donde Lambda puede ejecutar `PutItem`. |
| `s3_object_arns` | Vacío por defecto. Autoriza `GetObject` de objetos exactos o bajo prefijos concretos terminados en `/*`. |
| `kms_key_arns` | Vacío por defecto. Autoriza `Decrypt` con las claves indicadas. |

Usa `role_arn` al configurar la función Lambda para establecer la dependencia de la política inline. `role_name` permite identificar el recurso en IAM. El consumidor configura el proveedor, la cuenta y las políticas de los recursos. Para SQS o S3 cifrado con una clave de cliente, la política de clave también debe permitir el descifrado al rol. Terraform crea primero la política y AWS IAM puede tardar en propagar el cambio. Usa una referencia Git inmutable para cada versión del módulo.

| Perfil | Ejemplo |
| --- | --- |
| `queue-worker` | [Procesar la notificación de S3 como metadatos](examples/queue-worker/) |
| `queue-worker-encrypted` | [Leer objetos de un prefijo y usar una clave de cliente](examples/queue-worker-encrypted/) |

El rol IAM básico se ofrece sin cargo adicional. Los servicios autorizados se cotizan según su uso. [AWS IAM](https://aws.amazon.com/iam/getting-started/)

La [especificación del alta](change-spec.md) registra impacto, criterios y evidencia. Las pruebas del módulo usan un proveedor simulado.
