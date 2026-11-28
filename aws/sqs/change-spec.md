# Alta del módulo SQS

| Campo | Decisión |
| --- | --- |
| Origen y elección | El [issue #19](https://github.com/marcor0311/aws-cloud-consultant-agent/issues/19) pide baselines versionados, pruebas e impacto sobre consumidores. El PoC requiere un búfer para desacoplar S3 de Lambda y una DLQ observable. S3 envía eventos directamente a colas Standard, por lo que se seleccionó ese tipo. La aprobación humana queda pendiente. |
| Alcance | Alta de `aws/sqs` sobre `23364e3`. Candidato `0.1.0` con perfiles `standard` y `standard-kms`. |
| Contrato | Cola Standard, DLQ dedicada, reintentos configurables y política opcional que autoriza a un bucket S3 por ARN y cuenta. El proyecto consumidor aporta la notificación, el mapeo Lambda y, para el perfil KMS, la clave y sus permisos. |
| Aceptación | Pruebas simuladas de cifrado, autorización S3, políticas de TLS y redrive, defaults y validaciones de entradas. Aprovisionamiento, consulta de atributos, envío y recepción, redrive y limpieza con el emulador. |
| Impacto | Revisión de fuentes Terraform en el catálogo y el checkout de Consultant Agent. Alta de direcciones de colas y políticas en el estado consumidor. Para adoptar una cola existente hay que planificar importación y reconciliar las políticas. Un cambio de nombre debe drenar la cola antes del reemplazo. |
| Costo | Escenario bruto en USD y us-east-1 con 400.000 solicitudes Standard facturables en la cola y DLQ, con sondeo incluido: USD 0,16 mensuales de SQS para cada perfil. Para `standard-kms`, el conjunto de consumidores usa una clave y 20.000 solicitudes KMS al mes (USD 1,06 compartidos). Excluye franquicias, rotaciones facturables, transferencia y servicios externos. |
| Implementación | Recursos del proveedor AWS `6.71.0`, ejemplos con lockfile y pruebas simuladas. `scripts/validate.sh` descubre el módulo por su manifiesto. |
| Evidencia | [Registro de auditoría](audit-record.yaml). El [PR #47](https://github.com/marcor0311/aws-cloud-consultant-agent/pull/47) contiene el diseño de validación local del proyecto consumidor. |

AWS Price List Bulk publicó el 25 de noviembre de 2026 el SKU `8RN6B8U4MERHRXP3` a USD 0,40 por millón de solicitudes en su primer tramo. Usa solicitudes facturables, que pueden diferir del número de mensajes. La clave y sus solicitudes se contabilizan una sola vez entre consumidores. [Tarifas de SQS](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSQueueService/20261125150123/us-east-1/index.json) · [Tarifas KMS](https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/awskms/20261125150214/us-east-1/index.json)
