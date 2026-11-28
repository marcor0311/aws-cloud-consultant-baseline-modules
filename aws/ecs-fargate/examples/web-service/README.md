# Servicio web en ECS Fargate detrás de un ALB

Combina las subredes privadas del módulo [VPC](../../../vpc/), la imagen de [ECR](../../../ecr/) y el grupo de destinos y de seguridad del [ALB](../../../alb/). Las tareas no tienen IP pública y solo aceptan tráfico del balanceador.

Para validar, ejecuta `terraform init -backend=false -lockfile=readonly` y `terraform validate`. Usa `terraform.tfvars.example` para identificar los valores del consumidor.
