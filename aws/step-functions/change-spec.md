# Alta del módulo Step Functions

| Campo | Decisión |
| --- | --- |
| Origen y elección | Los procesos serverless de varios pasos necesitan orquestación con reintentos y estado visible. Se eligió el tipo Standard por su historial de ejecuciones y semántica de una sola ejecución. La aprobación humana queda pendiente. |
| Alcance | Alta de `aws/step-functions`. Candidato `0.1.0` con perfil `standard-workflow`. |
| Contrato | Máquina de estados, rol, logs y trazas. El consumidor aporta la definición, las funciones y los permisos adicionales. |
| Aceptación | Pruebas simuladas de tipo, logs, trazas, permisos y validación de la definición. Aprovisionamiento, ejecuciones aceptada y rechazada, y destrucción en AWS Emulator. |
| Impacto | Módulo nuevo sin consumidores. Cambiar el nombre reemplaza la máquina de estados y su historial. |
| Costo | USD y us-east-1: USD 0,025 por cada 1.000 transiciones de estado después de las 4.000 gratuitas. 100.000 ejecuciones de tres transiciones al mes, USD 7,40. |
| Implementación | Recursos del proveedor AWS `6.71.0`, ejemplo con lockfile y pruebas simuladas. |
| Evidencia | [Registro de auditoría](audit-record.yaml). |
