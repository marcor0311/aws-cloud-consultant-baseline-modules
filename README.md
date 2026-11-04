# Módulos de línea base AWS

Módulos Terraform reutilizables para que cada proyecto seleccione y combine configuraciones aprobadas.

| Módulo | Incluye |
| --- | --- |
| [S3](aws/s3/README.md) | Bucket privado, KMS, TLS y versionado. |
| [DynamoDB](aws/dynamodb/README.md) | On-demand o aprovisionado, KMS y recuperación. |
| [API Gateway](aws/api-gateway/README.md) | HTTP API con Lambda, IAM/JWT, logs y throttling. |

## Uso

```hcl
module "documents" {
  source = "git::https://github.com/marcor0311/aws-cloud-consultant-baseline-modules.git//aws/s3?ref=<commit-aprobado>"

  bucket_name = var.bucket_name
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}
```

Sustituir la referencia por un commit o tag aprobado. El proyecto configura proveedor, credenciales, backend y variables; `tags` requiere `Project`, `Environment`, `Owner` y `CostCenter`.

## Validación

Instalar Terraform 1.14.8 y Trivy 0.76.1. Los scripts inicializan y descargan el proveedor necesario.

```sh
scripts/validate.sh
scripts/security.sh
```

La CI comprueba formato, configuración, pruebas simuladas y seguridad. Binarios, cachés, estados y credenciales quedan fuera de Git.

La validación real en AWS y la aprobación de producción siguen pendientes.
