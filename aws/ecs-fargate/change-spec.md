# Alta del módulo ECS Fargate

| Campo | Decisión |
| --- | --- |
| Origen y elección | El catálogo solo ofrecía EKS para contenedores. Fargate cubre servicios web medianos sin administrar nodos ni Kubernetes. Se eligió ARM64 porque cuesta un 20 % menos que x86. La aprobación humana queda pendiente. |
| Alcance | Alta de `aws/ecs-fargate`. Candidato `0.1.0` con perfil `web-service`. |
| Contrato | Clúster, definición de tarea, roles de ejecución y aplicación, logs, grupo de seguridad opcional y servicio. El consumidor aporta red, imagen, balanceador, secretos y permisos de la aplicación. |
| Aceptación | Pruebas simuladas de red, despliegue, contenedor, permisos y validación de la imagen. Aprovisionamiento, lectura del servicio y la tarea, y destrucción en AWS Emulator. |
| Impacto | Módulo nuevo sin consumidores. Cambiar la imagen o las variables crea una revisión de tarea y un despliegue continuo. |
| Costo | USD y us-east-1, 730 horas por tarea ARM64 de 0,25 vCPU y 0,5 GB: USD 0,03238 por vCPU-hora y USD 0,00356 por GB-hora, USD 7,21 mensuales por tarea. Dos tareas, USD 14,42 sin logs ni balanceador. |
| Implementación | Recursos del proveedor AWS `6.71.0`, ejemplo con lockfile y pruebas simuladas. |
| Evidencia | [Registro de auditoría](audit-record.yaml). |
