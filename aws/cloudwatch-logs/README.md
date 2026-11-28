# Baseline de CloudWatch Logs

Crea un grupo de logs `STANDARD` con cifrado en reposo y retención finita. El PoC usa el grupo para observar el procesamiento y los errores de Lambda.

| Perfil | Comportamiento | Ejemplo |
| --- | --- | --- |
| `service-managed` | Cifrado administrado por CloudWatch Logs y retención predeterminada de 30 días | [Cifrado del servicio](examples/service-managed/) |
| `customer-managed` | Clave simétrica de KMS del consumidor y ejemplo con retención de 90 días | [Cifrado con KMS](examples/customer-managed/) |

## Contrato

| Entrada | Uso |
| --- | --- |
| `name` | Nombre completo del grupo. Para el destino predeterminado de Lambda usa `/aws/lambda/<función>`. |
| `tags` | Etiquetas corporativas del grupo. |
| `retention_in_days` | Plazo finito admitido por el servicio. Por defecto 30 días. |
| `kms_key_arn` | ARN opcional de la clave KMS simétrica de la región. |

La salida `log_group_name` configura el destino del productor. La salida `log_group_arn` contiene el ARN exacto del grupo y permite construir `<ARN>:log-stream:*` para permisos acotados de escritura. El consumidor define los permisos de la carga y el acceso a los logs. Cambiar el nombre reemplaza el grupo. La destrucción del grupo también elimina los eventos que contiene.

Para el perfil con clave propia, habilita al principal regional de CloudWatch Logs para usar la clave y limita la política al ARN del grupo mediante `kms:EncryptionContext:aws:logs:arn`. Conserva la clave y los permisos mientras existan logs cifrados con ella. Desasociarla cambia el cifrado de los eventos nuevos. [CloudWatch Logs y KMS](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html)

El módulo gestiona el grupo y su retención. La observabilidad que depende de alarmas, suscripciones, exportaciones o Logs Insights se configura en el consumidor.

## Verificación

`scripts/validate.sh cloudwatch-logs` ejecuta pruebas con el proveedor simulado y valida ambos ejemplos. Consulta la [especificación de alta](change-spec.md) y el [registro de auditoría](audit-record.yaml).
