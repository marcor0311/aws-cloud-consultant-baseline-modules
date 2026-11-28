# Alta del módulo ALB

| Campo | Decisión |
| --- | --- |
| Origen y elección | Las arquitecturas web y de contenedores necesitan una entrada HTTPS gestionada. Se eligió ALB porque enruta por ruta y host y registra destinos IP de Fargate y EKS. La aprobación humana queda pendiente. |
| Alcance | Alta de `aws/alb`. Candidato `0.1.0` con perfil `public-https`. |
| Contrato | Balanceador, grupo de seguridad, grupo de destinos y listeners HTTPS y HTTP. El consumidor aporta VPC, subredes, certificado, destinos, DNS y WAF. |
| Aceptación | Pruebas simuladas de TLS, redirección, reglas de red y validaciones. Aprovisionamiento, lectura de listeners y destrucción en AWS Emulator. |
| Impacto | Módulo nuevo sin consumidores. Cambiar `name` o `internal` reemplaza el balanceador y su nombre DNS. |
| Costo | USD y us-east-1, 730 horas: USD 0,0225 por hora (USD 16,43), una LCU promedio a USD 0,008 por hora (USD 5,84) y dos IPv4 públicas a USD 0,005 por hora (USD 7,30). Unos USD 29,57 mensuales antes de tráfico adicional. |
| Implementación | Recursos del proveedor AWS `6.71.0`, ejemplo con lockfile y pruebas simuladas. |
| Evidencia | [Registro de auditoría](audit-record.yaml). |
