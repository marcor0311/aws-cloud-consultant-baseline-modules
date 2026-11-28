# Rol para consumidor con datos cifrados

Además de la cola, el grupo de logs y la tabla, permite leer objetos de un prefijo y descifrar con una clave específica. La política de la clave debe autorizar al rol según las reglas de la cuenta. Los valores en `terraform.tfvars.example` son ilustrativos. Valida la configuración con `terraform init -backend=false` y `terraform validate`.
