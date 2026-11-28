# Alta del módulo ECR

| Campo | Decisión |
| --- | --- |
| Origen y elección | ECS Fargate y EKS necesitan un registro privado para las imágenes del proyecto. La aprobación humana queda pendiente. |
| Alcance | Alta de `aws/ecr`. Candidato `0.1.0` con perfil `private`. |
| Contrato | Repositorio, política de ciclo de vida y política opcional de descarga entre cuentas. El consumidor construye y publica las imágenes. |
| Aceptación | Pruebas simuladas de inmutabilidad, escaneo, cifrado, ciclo de vida y acceso externo. Aprovisionamiento, lectura de la política y destrucción en AWS Emulator. |
| Impacto | Módulo nuevo sin consumidores. Cambiar el nombre o el cifrado reemplaza el repositorio. |
| Costo | USD y us-east-1: USD 0,10 por GB al mes. Con 30 imágenes de 300 MB que comparten capas, unos 3 GB, USD 0,30 mensuales. La transferencia dentro de la región es gratuita. |
| Implementación | Recursos del proveedor AWS `6.71.0`, ejemplo con lockfile y pruebas simuladas. |
| Evidencia | [Registro de auditoría](audit-record.yaml). |
