# Clave con delegación a IAM

Este ejemplo configura el proveedor regional y crea una clave con la política predeterminada de AWS KMS. Otorga mediante IAM solo las operaciones de cifrado que requiera cada principal del proyecto.

Para validar, ejecuta `terraform init -backend=false -lockfile=readonly` y `terraform validate`. El archivo `terraform.tfvars.example` contiene valores ilustrativos para el consumidor.
