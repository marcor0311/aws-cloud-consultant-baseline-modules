# Clave con política para CloudWatch Logs

Usa la cuenta propietaria y el nombre exacto del grupo de logs regional. La política delega administración a IAM de la cuenta y autoriza a CloudWatch Logs solo para ese grupo. El consumidor provisiona el grupo y usa el output `key_arn` como destino de cifrado.

Para validar, ejecuta `terraform init -backend=false -lockfile=readonly` y `terraform validate`. Ajusta los valores ilustrativos de `terraform.tfvars.example` al entorno consumidor.
