# AWS KMS

Crea una clave simétrica de cifrado gestionada por el cliente y un alias regional. El módulo habilita la rotación automática y conserva la comprobación de bloqueo de políticas de AWS. El proyecto consumidor configura el proveedor y administra el estado.

| Perfil | Configuración | Ejemplo |
| --- | --- | --- |
| `iam-delegated` | Política predeterminada de AWS KMS para delegar permisos a IAM en la cuenta propietaria. | [Terraform](examples/iam-delegated/) |
| `customer-policy` | Política de clave proporcionada por el consumidor. El ejemplo autoriza a CloudWatch Logs para un grupo concreto. | [Terraform](examples/customer-policy/) |

| Entrada | Tipo | Valor predeterminado |
| --- | --- | --- |
| `alias_name` | `string` | Obligatoria. Usa el prefijo `alias/`. |
| `description` | `string` | `Regional encryption key` |
| `deletion_window_in_days` | `number` | `30`. AWS admite de 7 a 30 días. |
| `policy_json` | `string` | `null`. AWS KMS aplica la política predeterminada. |
| `tags` | `map(string)` | `{}` |

Usa `key_arn` para configurar el cifrado de S3, SQS, DynamoDB o CloudWatch Logs y declarar permisos sobre la clave. También se exponen `key_id` y `alias_name`. Verifica que cada servicio pueda usar la clave en la región elegida. Cuando definas una política completa, conserva el acceso de los administradores y autoriza explícitamente a los servicios que requieren acceso mediante la política de clave.

La rotación mantiene el ARN y el acceso a los datos cifrados. Antes de reemplazar o retirar una clave, migra cada recurso consumidor y conserva la clave anterior mientras existan datos que la necesiten. Al destruir la configuración, KMS programa la eliminación de la clave y aplica la ventana indicada.

[Especificación del cambio](change-spec.md)
