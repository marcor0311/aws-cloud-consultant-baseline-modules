# Uso y validación

## Requisitos

Instalar Terraform 1.14.8 y Trivy 0.76.1. Terraform descarga automáticamente el proveedor AWS al inicializar la configuración.

## Usar un módulo

En el repositorio del proyecto consumidor:

```hcl
module "documents" {
  source = "git::https://github.com/marcor0311/aws-cloud-consultant-baseline-modules.git//aws/s3?ref=<commit-aprobado>"

  bucket_name = var.bucket_name
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}
```

- Sustituir la referencia por un commit o tag aprobado.
- Configurar en el proyecto el proveedor AWS, autenticación, backend y variables.
- Incluir las etiquetas `Project`, `Environment`, `Owner` y `CostCenter`. `Environment` admite `dev`, `test`, `stage` y `prod`.
- Consultar las entradas, dependencias y ejemplos en el README de cada módulo.

## Validar cambios

Desde la raíz de este repo:

```sh
scripts/validate.sh
scripts/security.sh
```

El primer script inicializa y valida los módulos y ejemplos, y ejecuta las pruebas simuladas. El segundo analiza seguridad con Trivy. Ambos están configurados en GitHub Actions.

Las pruebas usan proveedores simulados y no requieren credenciales AWS. La verificación de integración en AWS se realiza por separado. Los binarios, cachés, estados, credenciales y reportes locales quedan excluidos de Git.

Las instrucciones para mantener módulos, lockfiles y revisiones están en [AGENTS.md](../AGENTS.md).
