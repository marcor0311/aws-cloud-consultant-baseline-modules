# Amazon VPC

Crea una VPC con una subred privada por zona y, con salida a Internet, una subred pública y un NAT Gateway por zona. Agrega endpoints de puerta de enlace para S3 y DynamoDB, que no tienen costo, y Flow Logs hacia CloudWatch Logs. El grupo de seguridad por defecto queda sin reglas.

| Perfil | Configuración | Ejemplo |
| --- | --- | --- |
| `private` | Subredes públicas y privadas, un NAT por zona. | [Terraform](examples/private/) |
| `isolated` | Solo subredes privadas, sin Internet Gateway ni NAT. | [Terraform](examples/isolated/) |

| Entrada | Tipo | Valor predeterminado |
| --- | --- | --- |
| `name` | `string` | Obligatoria |
| `availability_zones` | `list(string)` | Obligatoria. Dos o tres zonas. |
| `cidr_block` | `string` | `10.0.0.0/16` |
| `internet_egress` | `bool` | `true` |
| `single_nat_gateway` | `bool` | `false` |
| `flow_log_retention_days` | `number` | `30` |
| `tags` | `map(string)` | `{}` |

Salidas: `vpc_id`, `vpc_cidr_block`, `private_subnet_ids`, `public_subnet_ids`, `private_route_table_ids` y `flow_log_group_name`.

Cada zona usa un /20 público y un /20 privado del bloque. El NAT Gateway es el mayor costo fijo: alrededor de USD 33 mensuales por zona más el procesamiento de datos. En entornos de prueba conviene `single_nat_gateway = true`. Cambiar las zonas o el bloque reemplaza subredes, y con ello los recursos que viven en ellas.

[Especificación del cambio](change-spec.md)
