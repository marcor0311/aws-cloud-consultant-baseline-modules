# Alta del módulo Cognito

| Campo | Decisión |
| --- | --- |
| Origen y elección | Las APIs serverless y aplicaciones web necesitan autenticación de usuarios sin servidores propios. Cognito emite JWT que API Gateway valida sin código. La aprobación humana queda pendiente. |
| Alcance | Alta de `aws/cognito`. Candidato `0.1.0` con perfil `web-app`. |
| Contrato | Grupo de usuarios y cliente web. El consumidor aporta dominio, correo SES, autorizador y proveedores externos. |
| Aceptación | Pruebas simuladas de contraseñas, MFA, registro, cliente y validación de URL. Aprovisionamiento, alta de un usuario por administrador, lectura del cliente y destrucción en AWS Emulator. |
| Impacto | Módulo nuevo sin consumidores. Cambiar el nombre o los atributos de inicio de sesión reemplaza el grupo y sus usuarios. |
| Costo | USD y us-east-1, nivel Essentials: los primeros 10.000 usuarios activos mensuales sin cargo y USD 0,015 por usuario activo después. 1.000 usuarios activos, USD 0. |
| Implementación | Recursos del proveedor AWS `6.71.0`, ejemplo con lockfile y pruebas simuladas. |
| Evidencia | [Registro de auditoría](audit-record.yaml). |
