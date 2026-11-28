# Cifrado con clave KMS del consumidor

Este ejemplo usa una clave KMS en la región del grupo y retención de 90 días. Configura la política de la clave para que el servicio regional de Logs pueda usarla con el contexto de cifrado del grupo. Sustituye los valores de `terraform.tfvars.example` por los de tu proyecto. Ejecuta `terraform init` y `terraform plan -var-file=terraform.tfvars.example` desde este directorio con esos valores.
