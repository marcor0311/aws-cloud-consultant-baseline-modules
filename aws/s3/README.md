# S3 · almacenamiento privado

Crea un bucket con bloqueo de acceso público, ACLs deshabilitadas, cifrado KMS y denegación de HTTP. El versionado está habilitado y el borrado forzado deshabilitado por defecto.

- **Entradas obligatorias:** `bucket_name`, `kms_key_arn` y `tags`.
- **Variantes:** retención de objetos/versiones y destino de logs de acceso. Los valores predeterminados no expiran datos.
- **Outputs:** `bucket_id`, `bucket_arn` y `bucket_regional_domain_name`.
- [Entradas y validaciones](variables.tf) · [Ejemplo predeterminado](examples/default/) · [Retención](examples/retention/) · [Pruebas](tests/baseline.tftest.hcl).

La clave KMS debe existir en la región del bucket y permitir las operaciones de sus consumidores. Si se configura logging, el bucket destino y la política que permita entregas deben existir; el módulo no los administra.

Expirar objetos versionados crea marcadores de eliminación; el borrado de versiones anteriores se configura por separado. Cambiar de Enabled a Suspended no elimina versiones existentes. `force_destroy = false` evita vaciar un bucket durante destroy, pero no protege un bucket vacío; el proyecto debe controlar sus permisos y aprobación de destrucción. La denegación de HTTP no concede acceso a ninguna identidad.

No incluye Object Lock, replicación, CloudFront ni un bucket de logs central. Estas capacidades requieren un diseño explícito del proyecto. El módulo está pendiente de revisión y validación en AWS.
