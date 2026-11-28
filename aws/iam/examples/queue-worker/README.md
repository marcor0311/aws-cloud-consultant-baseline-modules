# Rol de ejecución para consumidor SQS

Proporciona los ARN de la cola fuente, el grupo de logs precreado y la tabla de destino. La función trabaja con los metadatos del mensaje. Los valores en `terraform.tfvars.example` son ilustrativos. Valida la configuración con `terraform init -backend=false` y `terraform validate`.
