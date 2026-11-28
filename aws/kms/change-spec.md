# Alta del módulo KMS

| Campo | Decisión |
| --- | --- |
| Origen y elección | El [issue #19](https://github.com/marcor0311/aws-cloud-consultant-agent/issues/19) pide baselines versionados, pruebas e impacto sobre consumidores. Para el PoC se eligió una clave KMS para reutilizar S3 y, donde aplique, cifrar SQS, DynamoDB o logs. La aprobación humana queda pendiente. |
| Alcance | Alta de `aws/kms` sobre `23364e3`. Candidato `0.1.0` con perfiles `iam-delegated` y `customer-policy`. |
| Contrato | Clave simétrica de una región y alias administrados en el estado del consumidor. Rotación habilitada, ventana de 30 días y comprobación de bloqueo de política. El perfil delegado usa los permisos IAM de la cuenta. El perfil con política permite configurar las autorizaciones requeridas por un servicio. |
| Aceptación | Plan simulado de ambos perfiles y rechazo de alias reservado, ventana inválida y política malformada. Validación del ejemplo de política para CloudWatch Logs. Aprovisionamiento, consulta de clave y alias, verificación de rotación, cifrado y descifrado, y programación de eliminación en el emulador. |
| Impacto | Revisión de fuentes Terraform en el catálogo y en el checkout de Consultant Agent. Alta de direcciones Terraform para la clave y el alias en el estado consumidor. Cada consumidor debe optar por el nuevo ARN. Los datos cifrados con claves previas requieren sus claves hasta completar la migración de datos. |
| Costo | Escenario bruto en USD y us-east-1 con una clave compartida y 20.000 llamadas simétricas al mes: USD 1,06 mensuales para cualquiera de los perfiles. Antes del alta, el catálogo ya contemplaba tarifas compartidas para claves del consumidor. Después del alta se contabilizan una vez por clave y volumen real. Excluye franquicias, rotaciones facturables y otros servicios. |
| Implementación | Recursos del proveedor AWS `6.71.0`, ejemplos con lockfile y pruebas simuladas. `scripts/validate.sh` descubre el módulo por su manifiesto. |
| Evidencia | [Registro de auditoría](audit-record.yaml). El [PR #47](https://github.com/marcor0311/aws-cloud-consultant-agent/pull/47) contiene la referencia de validación local del proyecto consumidor. |

AWS Price List Bulk publicó el 25 de noviembre de 2026 el SKU `U553K98XGDXCYHWS` a USD 1,00 por clave-mes y el SKU `MFEBZPX8NHM5FY7Z` a USD 0,03 por 10.000 solicitudes simétricas. [Catálogo us-east-1](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/awskms/20261125150214/us-east-1/index.json)
