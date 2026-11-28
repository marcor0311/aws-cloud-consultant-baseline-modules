# Alta del baseline Lambda

| Campo SDD | Resultado |
| --- | --- |
| Origen y elección | El [issue #19](https://github.com/marcor0311/aws-cloud-consultant-agent/issues/19) pide mantener baselines probados y revisados. El PoC usa Lambda para consumir SQS y procesar objetos S3. La elección corresponde al alcance del objetivo del PoC, con aprobación humana pendiente. |
| Alcance | Alta de `aws/lambda`, candidato 0.1.0 sobre el catálogo `23364e3`. Perfiles `zip` y `sqs-standard` en una sola implementación. |
| Contrato | [README](README.md) y [manifiesto](module.yaml). Entradas de ZIP local, runtime, rol y logs externos. Mapeo Standard opcional con validación de visibilidad y errores parciales. |
| Aceptación | Las pruebas simuladas cubren defaults, conexión de la cola, reporte parcial y entradas incompatibles. La prueba local verifica invocación, logs y errores parciales del PoC cuando el emulador soporta las operaciones requeridas. |
| Impacto | Alta de ruta y de direcciones de estado. La búsqueda local en el catálogo y el checkout de Consultant Agent no encontró consumidores de esta ruta. Un consumidor con Lambda existente debe planificar su importación y verificar el grupo y los permisos antes de habilitar el mapeo. |
| Costo | **USD 0.1033335/mes** en us-east-1 para 100.000 invocaciones x86_64 y 5.000 GB-s (256 MiB y 200 ms). Antes de franquicias e impuestos. Considera los cargos de SQS, CloudWatch Logs, S3 y DynamoDB por separado. |
| Implementación | Terraform AWS 6.71.0 en lockfiles, ejemplos, metadatos y pruebas. El workflow detecta el módulo por su manifiesto. |
| Evidencia | [Registro de auditoría](audit-record.yaml). Aprobación de producción pendiente del Arquitecto. |

La tarifa pública regional del 25 de noviembre de 2026 usa el SKU de solicitudes `GU2ZS9HVP6QTQ7KE` a USD 0.20 por millón y el de duración x86 `TG3M4CAGBA3NYQBH` a USD 0.0000166667 por GB-s en el primer tramo. El escenario supone uso bajo demanda, 512 MiB de almacenamiento efímero y ausencia de transferencia facturable. [AWS Price List](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSLambda/20261125205755/us-east-1/index.json)
