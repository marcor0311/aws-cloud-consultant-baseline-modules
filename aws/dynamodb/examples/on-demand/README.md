# dynamodb / on-demand

Tabla on-demand con recuperación, protección contra borrado y límites de uso explícitos.

Ejecutar desde esta carpeta dentro del checkout. Copiar `terraform.tfvars.example` a `terraform.tfvars` y sustituir nombres, etiquetas y ARNs de ejemplo. Las claves KMS y demás dependencias deben existir y contar con sus políticas de acceso.

```sh
terraform init
terraform plan -var-file=terraform.tfvars
```

Estos comandos no despliegan recursos. Aplicar el plan requiere revisión y autorización del proyecto. El proyecto consumidor administra su backend, estado, credenciales y región; este ejemplo no configura un backend remoto. Para un proyecto real, consumir el módulo mediante Git con una referencia aprobada, como indica el README del repo.
