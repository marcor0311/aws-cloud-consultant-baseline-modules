# Alta del módulo RDS PostgreSQL

| Campo | Decisión |
| --- | --- |
| Origen y elección | El catálogo solo tenía DynamoDB. Las aplicaciones web de tres capas necesitan una base relacional. Se eligió RDS for PostgreSQL por costo inicial bajo y compatibilidad amplia; Aurora queda para una versión posterior. La aprobación humana queda pendiente. |
| Alcance | Alta de `aws/rds-postgres`. Candidato `0.1.0` con perfiles `single-az` y `multi-az`. |
| Contrato | Instancia, grupo de subredes, grupo de parámetros con TLS obligatorio y grupo de seguridad opcional. El consumidor aporta red, clientes, clave KMS y migraciones de esquema. |
| Aceptación | Pruebas simuladas de cifrado, red, copias, protección y validaciones. Aprovisionamiento, lectura de la instancia y su secreto, y destrucción en AWS Emulator. |
| Impacto | Módulo nuevo sin consumidores. Cambios de identificador, clave o base inicial reemplazan la instancia. |
| Costo | USD y us-east-1, 730 horas. `single-az`: `db.t4g.micro` USD 0,016 por hora (USD 11,68) más 20 GB gp3 a USD 0,115 (USD 2,30), USD 13,98 mensuales. `multi-az`: `db.m7g.large` USD 0,336 por hora (USD 245,28) más 20 GB a USD 0,23 (USD 4,60), USD 249,88 mensuales. Copias hasta el tamaño de la base sin costo. |
| Implementación | Recursos del proveedor AWS `6.71.0`, ejemplos con lockfile y pruebas simuladas. |
| Evidencia | [Registro de auditoría](audit-record.yaml). |
