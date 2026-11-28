# Lambda desde ZIP local

Ejecuta `python3 -m zipfile -c function.zip handler.py` para empaquetar el handler. Sustituye los valores de `terraform.tfvars.example` por los de tu proveedor, rol de Lambda y grupo CloudWatch Logs. El rol debe poder escribir en ese grupo.

Ejecuta `terraform init` y `terraform plan -var-file=terraform.tfvars.example` desde este directorio con esos valores.
