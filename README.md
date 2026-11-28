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

Incluye ejemplos y pruebas automatizadas. La aprobación para producción está pendiente.

- [Agente de Codex y catálogo para el arquitecto](docs/agente/README.md)
- [Guía de uso y validación](docs/uso.md)
- [Instrucciones para el agente](AGENTS.md)

## Usar Codex o Claude Code en este repo

El repo trae su propia configuración en `.codex/` con límites de gasto (sin agentes en paralelo y esfuerzo `medium`), servidores MCP y el hook que verifica los módulos. Codex solo la aplica si el proyecto está marcado como confiable:

1. Abre el repo en Codex y acepta **Trust** cuando lo pregunte, o agrega a `~/.codex/config.toml`:

   ```toml
   [projects."/ruta/a/aws-cloud-consultant-baseline-modules"]
   trust_level = "trusted"
   ```

2. Comprueba que se aplica: `codex features list | grep '^multi_agent '` debe mostrar `false`.

Sin este paso, Codex ignora `.codex/` y usa tu configuración personal.

En Claude Code la misma configuración vive en `CLAUDE.md`, `.claude/` y `.mcp.json`; consulta [integraciones](docs/agente/integraciones.md#claude-code).
