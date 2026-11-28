# Alta del módulo VPC

| Campo | Decisión |
| --- | --- |
| Origen y elección | El catálogo no tenía red propia: EKS leía subredes existentes y no había base para ALB, ECS ni RDS. Se eligió una VPC de dos o tres zonas con NAT opcional porque cubre las arquitecturas web, de contenedores y de datos. La aprobación humana queda pendiente. |
| Alcance | Alta de `aws/vpc`. Candidato `0.1.0` con perfiles `private` e `isolated`. |
| Contrato | VPC, subredes por zona, rutas, NAT opcional, endpoints de S3 y DynamoDB y Flow Logs. El consumidor agrega grupos de seguridad, endpoints de interfaz y conectividad híbrida. |
| Aceptación | Pruebas simuladas de topología, aislamiento, grupo por defecto, Flow Logs y validaciones. Aprovisionamiento, lectura de subredes y rutas, y destrucción en AWS Emulator. |
| Impacto | Módulo nuevo sin consumidores. Cambiar zonas o bloque reemplaza subredes y los recursos que contienen. |
| Costo | USD y us-east-1, 730 horas: NAT Gateway USD 0,045 por hora (USD 32,85 por zona) más USD 0,045 por GB procesado, e IPv4 pública USD 0,005 por hora (USD 3,65 por NAT). El perfil `private` con dos zonas parte de USD 73 mensuales sin datos. `isolated` solo paga la ingesta de Flow Logs, USD 0,50 por GB. |
| Implementación | Recursos del proveedor AWS `6.71.0`, ejemplos con lockfile y pruebas simuladas. `scripts/validate.sh` descubre el módulo por su manifiesto. |
| Evidencia | [Registro de auditoría](audit-record.yaml). |
