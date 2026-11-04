# DynamoDB · tabla protegida

Crea una tabla con KMS corporativo, recuperación a un punto en el tiempo de 35 días y protección contra eliminación habilitada por defecto. Usa on-demand por defecto.

- **Entradas obligatorias:** `table_name`, `kms_key_arn` y `tags`.
- **Claves:** `pk` y `sk` de tipo string por defecto; permite claves configurables y tabla sin sort key.
- **On-demand:** `PAY_PER_REQUEST`, sin RCU/WCU; admite límites máximos opcionales de lectura y escritura.
- **Aprovisionado:** `PROVISIONED`, con RCU y WCU positivas obligatorias. No configura autoscaling.
- **TTL:** opcional, con un atributo numérico de timestamp Unix distinto de las claves.
- **Outputs:** `table_name`, `table_arn` y `table_id`.
- [Entradas y validaciones](variables.tf) · [On-demand](examples/on-demand/) · [Aprovisionado](examples/provisioned/) · [Pruebas](tests/baseline.tftest.hcl).

La clave KMS debe existir en la misma región y autorizar las operaciones requeridas por DynamoDB. Los límites on-demand producen throttling cuando se superan; no son un presupuesto financiero. El consumidor necesita políticas IAM para acceder a los datos.

Cambiar claves puede reemplazar la tabla. Para destruir una tabla protegida se debe deshabilitar la protección mediante un apply autorizado antes de destroy. No incluye índices secundarios, réplicas globales ni streams. El módulo está pendiente de revisión y validación en AWS.
