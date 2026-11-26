# Alta de CloudFront · candidato 0.1.0

| Campo | Decisión |
| --- | --- |
| Origen | Ejercicio de generación del agente de baselines del [issue #19](https://github.com/marcor0311/aws-cloud-consultant-agent/issues/19). |
| Alcance | Distribución HTTPS de contenido estático desde un bucket privado, con perfiles regional y global. |
| Contrato | OAC SigV4, WAFv2 global y bucket de logs existente. El consumidor incorpora la declaración de acceso en la política única de S3. Si usa SSE-KMS, integra el permiso en la clave. |
| Aceptación local | Probar OAC, redirección a HTTPS, métodos GET/HEAD, WAF, logs, alcance exacto del ARN y rechazo de orígenes incorrectos. Validar ambos ejemplos y analizarlos con Trivy. |
| Integración pendiente | En una cuenta autorizada, obtener un objeto por HTTPS a través de CloudFront, comprobar que S3 devuelve 403 sin credenciales, comprobar la redirección HTTP y confirmar el primer registro de acceso en el bucket de logs. |
| Costo | Subtotal de USD 9,50 para un millón de solicitudes HTTPS y 100 GB de salida en Estados Unidos. WAF, origen, logs, KMS y otros mercados se cuantifican según la carga. |
| Evidencia | [Auditoría](../aws/cloudfront/audit-record.yaml) y [guía para el arquitecto](../aws/cloudfront/README.md). |
