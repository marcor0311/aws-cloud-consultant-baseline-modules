# VPC privada con salida a Internet

Dos zonas con subredes públicas para balanceadores y NAT, y subredes privadas para cómputo y datos. Cada zona tiene su NAT Gateway. Para un entorno de pruebas, `single_nat_gateway = true` reduce el costo a un solo NAT.

Para validar, ejecuta `terraform init -backend=false -lockfile=readonly` y `terraform validate`. Usa `terraform.tfvars.example` para identificar los valores del consumidor.
