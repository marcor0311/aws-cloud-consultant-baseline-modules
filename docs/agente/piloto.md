# Lista de selección del piloto

**Requisito de ejemplo.** Elegir almacenamiento privado con historial, una tabla NoSQL con recuperación y una API HTTP autenticada. Región `us-east-1`. Los seis perfiles son candidatos `0.1.0`. El código Terraform evaluado corresponde al commit [`2450a17830d40439e4eb673d1459140b52d9b93f`](https://github.com/marcor0311/aws-cloud-consultant-baseline-modules/tree/2450a17830d40439e4eb673d1459140b52d9b93f/aws). Los tres registros indican revisión, aprobación de producción y validación en AWS pendientes.

| Requisito | Perfil y ejemplo Terraform | Qué elige el arquitecto | Cargo directo USD/mes |
| --- | --- | --- | ---: |
| Archivos privados | [S3 · default](../../aws/s3/examples/default/) | Historial de versiones sin expiración automática. Configurar el nombre y la clave KMS regional. | 3,31 |
| Archivos privados | [S3 · retention](../../aws/s3/examples/retention/) | Expirar objetos o versiones según la política de retención. El escenario asume 40 GB-mes menos de almacenamiento. | 2,39 |
| NoSQL con recuperación | [DynamoDB · on-demand](../../aws/dynamodb/examples/on-demand/) | Capacidad por demanda y recuperación de 35 días. Configurar tabla, clave KMS y permisos IAM de datos. | 4,72 |
| NoSQL con recuperación | [DynamoDB · provisioned](../../aws/dynamodb/examples/provisioned/) | Fijar RCU/WCU para uso predecible. El módulo aplica la misma protección y requiere que el consumidor gestione el ajuste de capacidad. | 7,35 |
| API autenticada | [API Gateway · IAM](../../aws/api-gateway/examples/iam/) | Clientes con SigV4. Requiere función Lambda y clave para cifrar los logs. | 1,56 |
| API autenticada | [API Gateway · JWT](../../aws/api-gateway/examples/jwt/) | Clientes con JWT. Requiere además emisor OIDC, audiencia y scopes según las rutas. | 1,56 |

Las dependencias compartidas suman **USD 4,24/mes** en el ejemplo. Incluyen dos claves KMS y sus operaciones, Lambda y salida a Internet. CloudWatch Logs está incluido en el cargo directo de API Gateway. Si se habilita un bucket de logging, un proveedor de identidad con cargo u otro servicio consumidor, añadir sus partidas al escenario.

| Selección | USD/mes |
| --- | ---: |
| S3 default, DynamoDB on-demand y API IAM | 13,83 |
| Cambiar S3 a retention | 12,91 |
| Cambiar DynamoDB a provisioned | 16,46 |
| Cambiar API a JWT con un emisor existente | 13,83 |

Las cifras usan [supuestos mensuales de ejemplo](../../examples/baseline-agent/usage.json) y [tarifas públicas de AWS por SKU](../../examples/baseline-agent/rates.us-east-1.json) consultadas el 26 de noviembre de 2026. Los resultados se pueden regenerar con el comando de estimación de la [guía](README.md#estimar-un-escenario). Una partida sin uso o tarifa se identifica como pendiente y evita presentar el subtotal como total completo.

## Evidencia del piloto

- Terraform 1.14.8 y proveedor AWS 6.71.0 validaron los tres módulos y sus seis ejemplos. Pasaron 7 pruebas simuladas de S3, 10 de DynamoDB y 9 de API Gateway.
- Trivy 0.76.1 ejecutó sus comprobaciones integradas en los seis ejemplos y reportó cero hallazgos de severidad alta o crítica.
- Los [registros de S3](../../aws/s3/audit-record.yaml), [DynamoDB](../../aws/dynamodb/audit-record.yaml) y [API Gateway](../../aws/api-gateway/audit-record.yaml) conservan el estado de revisión. El [diagrama editable](../../diagrams/baseline-piloto.yaml) muestra recursos y dependencias.
