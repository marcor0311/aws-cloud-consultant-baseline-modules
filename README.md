# Módulos de línea base AWS

Este proyecto reúne módulos Terraform que sirven como base para construir infraestructura en AWS. Permite reutilizar configuraciones comunes entre distintos proyectos de consultoría.

El arquitecto selecciona los módulos para su diseño y el ingeniero los integra en el repositorio de cada proyecto, ajustando sus parámetros.

| Módulo | Para qué sirve |
| --- | --- |
| [S3](aws/s3/README.md) | Almacenamiento privado de archivos. |
| [DynamoDB](aws/dynamodb/README.md) | Base de datos NoSQL con capacidad configurable. |
| [API Gateway](aws/api-gateway/README.md) | APIs HTTP conectadas a funciones Lambda. |

Incluye ejemplos y pruebas automatizadas. La aprobación para producción está pendiente.

[Guía de uso y validación](docs/uso.md) · [Instrucciones para el agente](AGENTS.md)
