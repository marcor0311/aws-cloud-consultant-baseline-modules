# AWS Cloud Consultant · Baseline Modules

Catálogo de módulos Terraform reutilizables para AWS. El arquitecto selecciona módulos y configuraciones; el proyecto consumidor los combina y administra región, identidad y estado.

| Módulo | Capacidad | Ejemplos |
| --- | --- | --- |
| [S3](aws/s3/README.md) | Almacenamiento privado con KMS, TLS y versionado. | [Predeterminado](aws/s3/examples/default/), [retención](aws/s3/examples/retention/) |
| [DynamoDB](aws/dynamodb/README.md) | Tabla cifrada con recuperación y protección contra borrado. | [On-demand](aws/dynamodb/examples/on-demand/), [aprovisionado](aws/dynamodb/examples/provisioned/) |
| [API Gateway](aws/api-gateway/README.md) | HTTP API con Lambda, autenticación, logs y throttling. | [IAM](aws/api-gateway/examples/iam/), [JWT](aws/api-gateway/examples/jwt/) |

## Estructura

```text
aws-cloud-consultant-baseline-modules/
├── README.md
├── AGENTS.md
├── .github/
│   ├── CODEOWNERS
│   └── workflows/validate.yml
├── scripts/
│   ├── validate.sh
│   └── security.sh
└── aws/
    ├── api-gateway/
    ├── dynamodb/
    └── s3/
        ├── README.md
        ├── module.yaml
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── versions.tf
        ├── audit-record.yaml
        ├── examples/
        └── tests/
```

Los tres módulos tienen la misma estructura. `module.yaml` permite descubrir capacidades y ejemplos sin ejecutar Terraform. `audit-record.yaml` conserva el estado de revisión y aprobación; no sustituye la evidencia de CI. No hay un framework spec-driven preinstalado: quien continúe el repo elegirá cómo inicializarlo.

## Consumo desde un proyecto

Terraform >= 1.9, < 2; proveedor AWS >= 6.71, < 7. La CI usa Terraform 1.14.8 y los lockfiles fijan el proveedor probado. Los módulos solo declaran requisitos: el consumidor configura el proveedor AWS, sus credenciales y su backend remoto.

```hcl
module "documents" {
  source = "git::https://github.com/marcor0311/aws-cloud-consultant-baseline-modules.git//aws/s3?ref=<commit-aprobado>"

  bucket_name = "nombre-global-unico-del-proyecto"
  kms_key_arn = var.storage_kms_key_arn
  tags = {
    Project     = "consulting-project"
    Environment = "prod"
    Owner       = "platform"
    CostCenter  = "engineering"
  }
}
```

Sustituir la referencia por un commit o tag aprobado. Git versiona el catálogo completo; los perfiles son ejemplos parametrizados, no copias del módulo ni releases independientes. La versión `0.1.0` de los manifiestos es una candidata, no un tag publicado.

Las etiquetas `Project`, `Environment`, `Owner` y `CostCenter` son obligatorias. `Environment` admite `dev`, `test`, `stage` y `prod`. Los nombres y ARNs deben pertenecer al proyecto real; los ejemplos contienen valores ficticios.

## Validación

Instalar Terraform 1.14.8 y Trivy 0.76.1 en el equipo. `terraform init` descarga automáticamente el proveedor AWS requerido; no hace falta configurar un plugin path ni una caché compartida. Los scripts ejecutan la inicialización necesaria.

Los binarios descargados, `.terraform/`, estados, credenciales y reportes locales quedan fuera de Git. Los archivos `.terraform.lock.hcl` solo registran versiones y checksums y sí se versionan. Para desplegar, el proyecto consumidor configura su autenticación AWS y backend; las pruebas simuladas no requieren credenciales.

Los lockfiles incluyen checksums para macOS ARM (`darwin_arm64`) y Linux x86_64 (`linux_amd64`). Al actualizar el proveedor, regenerarlos para ambas plataformas con `terraform providers lock -platform=darwin_arm64 -platform=linux_amd64` en cada configuración.

```sh
scripts/validate.sh
scripts/security.sh
```

El primer script ejecuta formato, init sin backend, validate, pruebas simuladas y validación de los seis ejemplos. Genera evidencia local en `reports/`, excluido de Git. El segundo evalúa los seis ejemplos con sus valores explícitos, requiere Trivy 0.76.1 y bloquea hallazgos HIGH/CRITICAL. Ambos están configurados en CI. Los lockfiles de los módulos y ejemplos hacen reproducible la selección del proveedor para estas comprobaciones; el consumidor mantiene su propio lockfile.

Las pruebas usan `mock_provider`, incluso en runs con `command = apply`: no llaman a AWS ni crean recursos. No verifican permisos IAM/KMS, cuotas, comportamiento real o compatibilidad de la región. La validación de integración en AWS y la aprobación de producción siguen pendientes.

## Revisión y entrega

El arquitecto es el revisor indicado en CODEOWNERS. Para exigir su aprobación, proteger `main` con revisión obligatoria de CODEOWNERS y los checks de CI; CODEOWNERS por sí solo no activa esa protección. Los proyectos mantienen su propia configuración de despliegue y estado. Este repositorio no ejecuta despliegues automáticos.

## Referencias

- [Estructura y módulos según AWS](https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/structure.html)
- [Estructura estándar de módulos Terraform](https://developer.hashicorp.com/terraform/language/modules/develop/structure)
- [Pruebas con proveedores simulados](https://developer.hashicorp.com/terraform/language/tests/mocking)
