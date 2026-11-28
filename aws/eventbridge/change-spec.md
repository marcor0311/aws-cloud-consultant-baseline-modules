# Alta del módulo EventBridge

| Campo | Decisión |
| --- | --- |
| Origen y elección | Las arquitecturas serverless por eventos necesitan enrutar eventos de dominio por contenido. EventBridge filtra por patrón, reintenta y archiva sin código. La aprobación humana queda pendiente. |
| Alcance | Alta de `aws/eventbridge`. Candidato `0.1.0` con perfil `custom-bus`. |
| Contrato | Bus, archivo opcional, reglas, destinos con reintentos y DLQ, y permisos Lambda. El consumidor aporta destinos, sus políticas y la DLQ. |
| Aceptación | Pruebas simuladas de reintentos, DLQ, archivo, permisos y validaciones. Aprovisionamiento, publicación de un evento, recepción en la cola destino y destrucción en AWS Emulator. |
| Impacto | Módulo nuevo sin consumidores. Renombrar una regla la reemplaza y puede perder eventos durante el cambio. |
| Costo | USD y us-east-1: USD 1,00 por millón de eventos personalizados publicados, USD 0,10 por GB archivado procesado y USD 0,023 por GB-mes almacenado. Un millón de eventos de 1 KB al mes, unos USD 1,12. |
| Implementación | Recursos del proveedor AWS `6.71.0`, ejemplo con lockfile y pruebas simuladas. |
| Evidencia | [Registro de auditoría](audit-record.yaml). |
