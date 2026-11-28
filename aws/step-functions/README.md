# AWS Step Functions

Crea una máquina de estados Standard a partir de una definición en Amazon States Language, con un rol que solo invoca las funciones indicadas, logs de ejecución en CloudWatch Logs y trazas X-Ray.

| Perfil | Configuración | Ejemplo |
| --- | --- | --- |
| `standard-workflow` | Flujo con decisión, éxito y fallo. | [Terraform](examples/standard-workflow/) |

| Entrada | Tipo | Valor predeterminado |
| --- | --- | --- |
| `name` | `string` | Obligatoria |
| `definition` | `string` | Obligatoria. JSON con `StartAt` y `States`. |
| `lambda_function_arns` | `list(string)` | `[]` |
| `additional_policy_json` | `string` | `null` |
| `log_level` | `string` | `ERROR` |
| `log_retention_days` | `number` | `30` |
| `tags` | `map(string)` | `{}` |

Salidas: `state_machine_arn`, `role_arn` y `log_group_name`.

Los logs no incluyen la entrada ni la salida de cada paso para no registrar datos sensibles. Para depurar, sube temporalmente `log_level` a `ALL`. Los permisos de entrega de logs y X-Ray usan `Resource: "*"` porque esas APIs no admiten recursos concretos. Cambiar la definición actualiza el flujo sin afectar ejecuciones en curso.

[Especificación del cambio](change-spec.md)
