# Flujo Standard con decisión

Un flujo mínimo que acepta o rechaza un pedido según su importe. En un proyecto real, los estados `Task` invocan funciones del módulo [Lambda](../../../lambda/) indicadas en `lambda_function_arns`.

Para validar, ejecuta `terraform init -backend=false -lockfile=readonly` y `terraform validate`. Usa `terraform.tfvars.example` para identificar los valores del consumidor.
