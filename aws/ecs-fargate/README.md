# Amazon ECS Fargate

Crea un clúster con Container Insights, una definición de tarea Fargate ARM64, el rol de ejecución, el rol de la aplicación, un grupo de logs y el servicio. Las tareas corren en subredes privadas sin IP pública, con sistema de archivos de solo lectura, y el despliegue se revierte solo si falla.

| Perfil | Configuración | Ejemplo |
| --- | --- | --- |
| `web-service` | Dos tareas detrás del grupo de destinos de un ALB. | [Terraform](examples/web-service/) |

| Entrada | Tipo | Valor predeterminado |
| --- | --- | --- |
| `name` | `string` | Obligatoria |
| `image` | `string` | Obligatoria. Etiqueta concreta o digest, nunca `latest`. |
| `vpc_id` | `string` | Obligatoria |
| `subnet_ids` | `list(string)` | Obligatoria |
| `container_port` | `number` | `8080` |
| `cpu` / `memory` | `number` | `256` / `512` |
| `desired_count` | `number` | `2` |
| `source_security_group_id` | `string` | `null` |
| `egress_cidr_blocks` | `list(string)` | `null`, que solo permite la VPC y S3 |
| `target_group_arn` | `string` | `null` |
| `security_group_ids` | `list(string)` | `null`, que crea un grupo propio |
| `environment` | `map(string)` | `{}` |
| `secrets` | `map(string)` | `{}` |
| `task_role_policy_json` | `string` | `null` |
| `log_retention_days` | `number` | `30` |
| `tags` | `map(string)` | `{}` |

Salidas: `cluster_arn`, `service_name`, `task_definition_arn`, `task_role_arn`, `security_group_id` y `log_group_name`.

Las tareas necesitan HTTPS para descargar la imagen y enviar logs. Por defecto solo salen a la VPC y a S3, así que hacen falta endpoints de interfaz de `ecr.api`, `ecr.dkr`, `logs` y `secretsmanager`. Si en cambio usas NAT, pasa `egress_cidr_blocks = ["0.0.0.0/0"]` y acepta el hallazgo AWS-0104 de Trivy en el proyecto. La imagen debe estar compilada para ARM64. Como el sistema de archivos es de solo lectura, la aplicación debe escribir en volúmenes o en servicios externos.

[Especificación del cambio](change-spec.md)
