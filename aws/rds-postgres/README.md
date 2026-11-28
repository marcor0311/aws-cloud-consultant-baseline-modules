# Amazon RDS for PostgreSQL

Crea una instancia PostgreSQL en subredes privadas con almacenamiento gp3 cifrado y crecimiento automático. Las conexiones exigen TLS. El usuario maestro vive en Secrets Manager con rotación gestionada por RDS. Incluye autenticación IAM, siete días de copias, protección contra borrado y copia final.

| Perfil | Configuración | Ejemplo |
| --- | --- | --- |
| `single-az` | `db.t4g.micro` en una zona. | [Terraform](examples/single-az/) |
| `multi-az` | `db.m7g.large` con réplica en espera. | [Terraform](examples/multi-az/) |

| Entrada | Tipo | Valor predeterminado |
| --- | --- | --- |
| `identifier` | `string` | Obligatoria |
| `vpc_id` | `string` | Obligatoria |
| `subnet_ids` | `list(string)` | Obligatoria. Dos zonas o más. |
| `client_security_group_ids` | `list(string)` | `[]` |
| `security_group_ids` | `list(string)` | `null`, que crea un grupo propio |
| `engine_version` | `string` | `17` |
| `instance_class` | `string` | `db.t4g.micro` |
| `allocated_storage_gb` / `max_allocated_storage_gb` | `number` | `20` / `100` |
| `multi_az` | `bool` | `false` |
| `database_name` | `string` | `app` |
| `kms_key_arn` | `string` | `null` |
| `backup_retention_days` | `number` | `7` |
| `deletion_protection` | `bool` | `true` |
| `skip_final_snapshot` | `bool` | `false` |
| `tags` | `map(string)` | `{}` |

Salidas: `endpoint`, `port`, `database_name`, `master_user_secret_arn`, `resource_id` y `security_group_id`.

Para ECS, pasa `master_user_secret_arn` en `secrets` y agrega el `security_group_id` del servicio a `client_security_group_ids`. Cambiar `identifier`, `kms_key_arn` o `database_name` reemplaza la instancia; restaura desde la copia final si ocurre. Para destruir, primero desactiva `deletion_protection`.

[Especificación del cambio](change-spec.md)
