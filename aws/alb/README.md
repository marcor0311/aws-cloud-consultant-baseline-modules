# Application Load Balancer

Crea un ALB con listener HTTPS, redirección permanente desde HTTP, un grupo de seguridad propio y un grupo de destinos. Usa la política `ELBSecurityPolicy-TLS13-1-2-2021-06`, descarta cabeceras inválidas y limita la salida al puerto de los destinos dentro de la VPC.

| Perfil | Configuración | Ejemplo |
| --- | --- | --- |
| `public-https` | Balanceador público en subredes públicas con certificado de ACM. | [Terraform](examples/public-https/) |

| Entrada | Tipo | Valor predeterminado |
| --- | --- | --- |
| `name` | `string` | Obligatoria. Hasta 26 caracteres. |
| `vpc_id` | `string` | Obligatoria |
| `subnet_ids` | `list(string)` | Obligatoria. Dos zonas o más. |
| `certificate_arn` | `string` | Obligatoria |
| `internal` | `bool` | `false` |
| `ingress_cidr_blocks` | `list(string)` | `["0.0.0.0/0"]` |
| `target_port` | `number` | `8080` |
| `target_type` | `string` | `ip` |
| `health_check_path` | `string` | `/health` |
| `security_group_ids` | `list(string)` | `null`, que crea un grupo propio |
| `access_logs_bucket` | `string` | `null` |
| `deletion_protection` | `bool` | `true` |
| `tags` | `map(string)` | `{}` |

Salidas: `load_balancer_arn`, `dns_name`, `zone_id`, `target_group_arn`, `security_group_id` y `https_listener_arn`.

Los destinos deben aceptar tráfico desde `security_group_id` en `target_port`. Para una aplicación pública conviene asociar AWS WAF al `load_balancer_arn`. Para habilitar `access_logs_bucket`, la política del bucket debe permitir la entrega de logs de Elastic Load Balancing. Con `deletion_protection = true`, desactívala antes de destruir el balanceador.

[Especificación del cambio](change-spec.md)
