# Módulos de línea base AWS

Este proyecto reúne módulos Terraform que sirven como base para construir infraestructura en AWS. Permite reutilizar configuraciones comunes entre distintos proyectos de consultoría.

El arquitecto selecciona los módulos para su diseño y el ingeniero los integra en el repositorio de cada proyecto, ajustando sus parámetros.

| Módulo | Para qué sirve |
| --- | --- |
| [S3](aws/s3/README.md) | Almacenamiento privado de archivos. |
| [DynamoDB](aws/dynamodb/README.md) | Base de datos NoSQL con capacidad configurable. |
| [API Gateway](aws/api-gateway/README.md) | APIs HTTP conectadas a funciones Lambda. |
| [EKS](aws/eks/README.md) | Kubernetes privado con nodos EC2 administrados. |
| [CloudFront](aws/cloudfront/README.md) | CDN HTTPS con origen S3 privado. |
| [KMS](aws/kms/README.md) | Claves de cifrado administradas por el cliente con rotación. |
| [CloudWatch Logs](aws/cloudwatch-logs/README.md) | Grupos de logs con retención y cifrado. |
| [SQS](aws/sqs/README.md) | Colas estándar con cola de mensajes fallidos y solo TLS. |
| [IAM](aws/iam/README.md) | Roles de mínimo privilegio para servicios. |
| [Lambda](aws/lambda/README.md) | Funciones con logs, rol propio y disparador SQS opcional. |
| [VPC](aws/vpc/README.md) | Red con subredes privadas por zona, NAT opcional y Flow Logs. |
| [ALB](aws/alb/README.md) | Balanceador HTTPS con redirección desde HTTP. |
| [ECR](aws/ecr/README.md) | Repositorio de imágenes con etiquetas inmutables y escaneo. |
| [ECS Fargate](aws/ecs-fargate/README.md) | Servicio de contenedores privado detrás de un ALB. |
| [RDS PostgreSQL](aws/rds-postgres/README.md) | Base relacional con TLS, credenciales en Secrets Manager y copias. |
| [SNS](aws/sns/README.md) | Tópico cifrado con fan-out a colas SQS. |
| [EventBridge](aws/eventbridge/README.md) | Bus de eventos con reglas por patrón, DLQ y archivo. |
| [Step Functions](aws/step-functions/README.md) | Orquestación de flujos con logs y trazas. |
| [Cognito](aws/cognito/README.md) | Usuarios y cliente web OAuth para aplicaciones y APIs. |

| Arquitectura | Módulos |
| --- | --- |
| Web de tres capas | VPC, ALB, ECS Fargate o EKS, RDS PostgreSQL |
| Contenedores | VPC, ECR, ECS Fargate o EKS, ALB |
| Serverless con API | API Gateway, Lambda, DynamoDB, Cognito |
| Serverless por eventos | EventBridge, SNS, SQS, Lambda, Step Functions |
| Sitio estático | S3, CloudFront |

Todas usan KMS, IAM y CloudWatch Logs como base común.

Incluye ejemplos y pruebas automatizadas. La CI valida solo los módulos afectados por cada cambio (Terraform, seguridad y AWS Emulator); en `main` las ejecuciones se encolan y no se cancelan. La aprobación para producción está pendiente.

- [Agente de Codex y catálogo para el arquitecto](docs/agente/README.md)
- [Guía de uso y validación](docs/uso.md)
- [Instrucciones para el agente](AGENTS.md)

## Usar Codex o Claude Code en este repo

El repo trae su propia configuración en `.codex/` con límites de gasto (sin agentes en paralelo y esfuerzo `low`; el modelo es el que cada persona tenga seleccionado), servidores MCP y el hook que verifica los módulos. Codex solo la aplica si el proyecto está marcado como confiable:

1. Abre el repo en Codex y acepta **Trust** cuando lo pregunte, o agrega a `~/.codex/config.toml`:

   ```toml
   [projects."/ruta/a/aws-cloud-consultant-baseline-modules"]
   trust_level = "trusted"
   ```

2. Comprueba que se aplica: `codex features list | grep '^multi_agent '` debe mostrar `false`.

Sin este paso, Codex ignora `.codex/` y usa tu configuración personal.

En Claude Code la misma configuración vive en `CLAUDE.md`, `.claude/` y `.mcp.json`; consulta [integraciones](docs/agente/integraciones.md#claude-code).
