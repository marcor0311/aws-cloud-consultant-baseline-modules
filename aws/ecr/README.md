# Amazon ECR

Crea un repositorio privado con etiquetas inmutables, escaneo de vulnerabilidades al publicar y una política de ciclo de vida. Las imágenes sin etiqueta expiran a los siete días y se conservan las 30 etiquetadas más recientes.

| Perfil | Configuración | Ejemplo |
| --- | --- | --- |
| `private` | Cifrado AES-256 y acceso solo desde la cuenta. | [Terraform](examples/private/) |

| Entrada | Tipo | Valor predeterminado |
| --- | --- | --- |
| `name` | `string` | Obligatoria |
| `kms_key_arn` | `string` | `null`, que usa AES-256 |
| `keep_tagged_images` | `number` | `30` |
| `untagged_expiration_days` | `number` | `7` |
| `pull_principal_arns` | `list(string)` | `[]` |
| `force_delete` | `bool` | `false` |
| `tags` | `map(string)` | `{}` |

Salidas: `repository_arn`, `repository_url` y `repository_name`.

Con etiquetas inmutables cada despliegue publica una etiqueta nueva, por ejemplo el commit. El rol de ejecución de ECS necesita `ecr:GetAuthorizationToken` y permisos de descarga sobre `repository_arn`. Cambiar el cifrado reemplaza el repositorio y borra sus imágenes.

[Especificación del cambio](change-spec.md)
