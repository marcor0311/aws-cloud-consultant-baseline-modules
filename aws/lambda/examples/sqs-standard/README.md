# Lambda desde SQS Standard

Empaqueta el handler con `python3 -m zipfile -c function.zip handler.py`. Sustituye los valores de `terraform.tfvars.example` por los de tu proveedor, rol, grupo de logs y cola Standard. Usa el timeout de visibilidad real de la cola. El rol también necesita los permisos de lectura, atributos y borrado de SQS.

Ejecuta `terraform init` y `terraform plan -var-file=terraform.tfvars.example` desde este directorio con esos valores. El handler de muestra devuelve los identificadores de los mensajes cuyo cuerpo está vacío para que SQS pueda reintentarlos.
