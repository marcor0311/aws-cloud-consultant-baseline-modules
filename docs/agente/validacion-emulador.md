# Validación local con AWS Emulator

La CI y la skill `validate-baseline-emulator` ejecutan plan, apply, una comprobación y destroy de cada perfil afectado contra [AWS Emulator](https://docs.aws.amazon.com/emulator/latest/userguide/getting-started-agent.html) 1.0.385, fijado en `scripts/emulator/Dockerfile`. Requiere Docker, Terraform 1.14.8 y Python 3.10 o superior.

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r scripts/requirements-baseline.txt
docker build --platform linux/amd64 -t baseline-poc-aws-emulator:1.0.385 scripts/emulator
.venv/bin/python scripts/test_emulator.py --case s3/default --evidence reports/s3-default.json
```

## Cobertura

| Módulo | Comprobación | Estado |
| --- | --- | --- |
| S3 | Funcional (objetos, cifrado, etiquetas) | Pasa |
| DynamoDB | Funcional (lectura y escritura) | Pasa |
| CloudFront | Convergencia del estado Terraform | Pasa |
| API Gateway | — | No aplica: `terraform apply` no termina en el emulador |
| EKS | — | No aplica: el ejemplo lee subredes reales con data sources |
| VPC | Funcional (subredes, NAT, endpoints, grupo por defecto cerrado, Flow Logs) | Pasa |
| ALB | Funcional (listeners HTTPS y redirección, grupo de destinos) | Pasa con grupo de seguridad del fixture* |
| ECR | Funcional (inmutabilidad, escaneo, ciclo de vida) | Pasa |
| ECS Fargate | Funcional (servicio privado, reversión, definición de tarea) | Pasa con grupo de seguridad del fixture* |
| RDS PostgreSQL | Funcional (cifrado, TLS obligatorio, secreto maestro), ambos perfiles | Pasa con grupo de seguridad del fixture* |
| SNS | Funcional (publicación y entrega en bruto a dos colas) | Pasa; la denegación sin TLS se verifica en la política** |
| EventBridge | Funcional (enrutamiento por patrón, DLQ, archivo) | Pasa |
| Step Functions | Funcional (ejecución aceptada y rechazada) | Pasa |
| Cognito | Funcional (política de contraseñas, cliente público, alta por administrador) | Pasa |
| SQS | — | No aplica: el emulador deniega por HTTPS una política `Deny` con `aws:SecureTransport` y `aws:PrincipalIsAWSService` combinadas, que en AWS no aplica. La política del módulo no se debilita. El consumo SQS se cubre con `lambda/sqs-standard` |

\* Al crear un `aws_security_group`, el proveedor revoca la salida por defecto con puertos `0` y protocolo `-1`. AWS ignora los puertos con ese protocolo, pero el emulador 1.0.385 responde `InvalidPermission.NotFound`. Estos módulos aceptan `security_group_ids` y el caso del emulador pasa un grupo creado por API. La creación del grupo propio y sus reglas quedan cubiertas por las pruebas simuladas.

\*\* El emulador evalúa `aws:SecureTransport` como falso en SNS aunque la llamada use HTTPS. La prueba verifica la denegación, la retira solo dentro del emulador para probar la entrega y restaura la política.

AWS Emulator 1.0.385 responde a las APIs de los veinte servicios del catálogo (verificado el 28 de noviembre de 2026); las exclusiones son de casos concretos, no de servicios. La CI excluye API Gateway, EKS y SQS del job del emulador y el check **Validación de baselines** los reporta como "no aplica". Para incorporarlos se necesita un adaptador funcional o fixtures de red emulados.

En un PR, `scripts/select_emulator_cases.py` compara HEAD con la rama base y selecciona los perfiles afectados. Un cambio compartido de validación incluye S3 y DynamoDB como muestra, y la ejecución manual del workflow valida todo el catálogo emulable.

Adjunta al PR la evidencia JSON de cada caso, con la versión del emulador y sus `limitations`. El emulador usa una sola cuenta y región en memoria; los resultados de IAM y KMS no demuestran la aplicación de políticas en AWS.
