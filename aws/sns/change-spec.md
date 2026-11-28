# Alta del módulo SNS

| Campo | Decisión |
| --- | --- |
| Origen y elección | Las arquitecturas por eventos necesitan distribuir un mismo evento a varios consumidores. SNS con colas SQS suscritas desacopla a cada consumidor y conserva reintentos y DLQ por cola. La aprobación humana queda pendiente. |
| Alcance | Alta de `aws/sns`. Candidato `0.1.0` con perfil `fan-out`. |
| Contrato | Tópico, política y suscripciones SQS. El consumidor aporta la clave KMS, las colas, sus políticas y los publicadores. |
| Aceptación | Pruebas simuladas de cifrado, política y suscripciones. Aprovisionamiento, publicación, recepción en cada cola y destrucción en AWS Emulator. |
| Impacto | Módulo nuevo sin consumidores. Cambiar el nombre reemplaza el tópico y sus suscripciones. |
| Costo | USD y us-east-1: USD 0,50 por millón de publicaciones después del primer millón gratuito; la entrega a SQS no tiene cargo. Un millón de eventos al mes con dos colas, USD 0,50 más el costo de SQS. La clave KMS cuesta USD 1 mensual más sus solicitudes y se comparte entre consumidores. |
| Implementación | Recursos del proveedor AWS `6.71.0`, ejemplo con lockfile y pruebas simuladas. |
| Evidencia | [Registro de auditoría](audit-record.yaml). |
