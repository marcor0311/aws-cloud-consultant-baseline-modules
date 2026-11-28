# Alta del baseline CloudWatch Logs

| Campo SDD | Resultado |
| --- | --- |
| Origen y elección | El [issue #19](https://github.com/marcor0311/aws-cloud-consultant-agent/issues/19) pide mantener baselines probados y revisados. El PoC usa CloudWatch Logs para verificar procesamiento y fallos de Lambda. La elección corresponde al alcance del objetivo del PoC, con aprobación humana pendiente. |
| Alcance | Alta de `aws/cloudwatch-logs`, candidato 0.1.0 sobre el catálogo `23364e3`. Perfiles `service-managed` y `customer-managed` en una sola implementación. |
| Contrato | [README](README.md) y [manifiesto](module.yaml). Grupo STANDARD regional, retención finita y clave KMS opcional cuya política administra el consumidor. |
| Aceptación | Las pruebas simuladas cubren defaults y configuración de clave, rechazan la retención indefinida y requieren el ARN de clave. La validación local verifica grupo, streams y lectura de eventos en los perfiles aplicables. |
| Impacto | Alta de ruta y de dirección de estado. La búsqueda local en el catálogo y el checkout de Consultant Agent no encontró consumidores de esta ruta. Importa por nombre un grupo existente antes de aplicar y revisa la retención para preservar datos vigentes. Cambiar el nombre reemplaza el recurso. |
| Costo | **USD 0.5075/mes** en us-east-1 para 1 GB de ingesta STANDARD y 0.25 GB-mes de archivo comprimido, antes de franquicias e impuestos. Para clave propia incluye el costo incremental de KMS según uso o comparte la partida de la clave existente. |
| Implementación | Terraform AWS 6.71.0 en lockfiles, ejemplos, metadatos y pruebas. El workflow detecta el módulo por su manifiesto. |
| Evidencia | [Registro de auditoría](audit-record.yaml). Aprobación de producción pendiente del Arquitecto. |

La tarifa pública regional del 25 de noviembre de 2026 usa el SKU `S8QGXX5R2BKKMDSJ` a USD 0.50 por GB de ingesta en el primer tramo y `6K9ADYQAHV5KX9KZ` a USD 0.03 por GB-mes archivado. El escenario supone que el consumidor no usa Insights, suscripciones ni exportaciones. [AWS Price List](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonCloudWatch/20261125150240/us-east-1/index.json)
