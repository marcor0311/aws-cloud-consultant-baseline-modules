# EKS · clúster privado con nodos administrados

Crea un clúster EKS con endpoint Kubernetes privado, un grupo administrado de nodos EC2 On-Demand, acceso administrativo explícito, cifrado KMS y logs del plano de control.

- **Entradas obligatorias:** `name`, `kubernetes_version`, `vpc_id`, `private_subnet_ids`, `iam_role_arns`, `kms_key_arns` y `tags`.
- **Controles:** acceso Kubernetes mediante EKS Access Entries, sin privilegios automáticos para el creador. Protección contra eliminación, plan de soporte `STANDARD`, cinco tipos de logs cifrados durante 90 días y discos raíz gp3 cifrados con IMDSv2.
- **Variantes:** [`standard`](examples/standard/) inicia dos nodos `m6i.large` y [`scaled`](examples/scaled/) inicia tres. Ambos usan Amazon Linux 2023 x86-64 y 40 GiB por nodo.
- **Outputs:** nombre y ARN del clúster, endpoint privado, certificado CA, nombre del grupo de nodos y ARN del grupo de logs.
- [Entradas y validaciones](variables.tf) · [Pruebas](tests/baseline.tftest.hcl) · [Auditoría](audit-record.yaml) · [Diagrama editable](../../diagrams/baseline-eks.yaml).

## Prerrequisitos

- VPC existente con soporte DNS y nombres de host habilitados. Usa subredes privadas en al menos dos zonas, con espacio IP para los ENI de EKS, los nodos y los pods. Terraform comprueba VPC, zonas y asignación automática de IP pública. El consumidor verifica las tablas de rutas y el acceso administrativo desde la VPC o una red conectada.
- Da a los nodos acceso a ECR, S3 y las APIs que usen los componentes del clúster mediante NAT o endpoints privados. Usa el rol de clúster con confianza en `eks.amazonaws.com` y permisos de EKS. El rol de nodos necesita confianza en EC2, permisos de kubelet y lectura de ECR. Proporciona permisos al VPC CNI desde su identidad dedicada o desde el rol de nodos si aún no has configurado esa identidad. El tercer rol es el administrador Kubernetes autorizado.
- Configura las políticas de las claves KMS en la región del clúster. La clave de Kubernetes debe permitir el uso y los grants de EKS. La de logs debe autorizar al principal regional de CloudWatch Logs con el contexto del grupo `/aws/eks/<nombre>/cluster`. EBS usa la clave predeterminada de cifrado de la cuenta para la región.
- Elige una versión Kubernetes minor bajo soporte estándar. El ejemplo usa `1.36` y la política `STANDARD` evita cobrar soporte extendido. Planifica las actualizaciones de Kubernetes, AMI y complementos con el ciclo de soporte de EKS.

[Red y subredes](https://docs.aws.amazon.com/eks/latest/best-practices/subnets.html) · [Rol IAM de nodos](https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html) · [Ciclo de Kubernetes](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html)

## Costo aproximado

Precios públicos On-Demand en `us-east-1` para 730 horas, 5 GB de ingestión y 10 GB-mes de logs, dos claves KMS y 10.000 operaciones KMS de ejemplo.

| Perfil | EKS | EC2 | EBS | Logs y KMS | Subtotal USD/mes |
| --- | ---: | ---: | ---: | ---: | ---: |
| `standard` · 2 nodos | 73,00 | 140,16 | 6,40 | 4,83 | **224,39** |
| `scaled` · 3 nodos | 73,00 | 210,24 | 9,60 | 4,83 | **297,67** |

Añade el costo de NAT, endpoints, transferencia entre zonas y tráfico externo según la red disponible. Workloads, balanceadores, almacenamiento persistente, copias de seguridad y capacidad temporal de actualizaciones se estiman aparte. El JSON marca la red pendiente y entrega un subtotal. Para otro tipo de instancia, reemplaza la tarifa EC2 por el SKU regional correspondiente.

Genera la lista para el arquitecto desde la raíz del repositorio.

```sh
python scripts/baseline.py shopping-list \
  examples/baseline-agent/eks-usage.json examples/baseline-agent/eks-rates.us-east-1.json \
  --format markdown
```

[Precios EKS](https://aws.amazon.com/eks/pricing/) · [Tarifas por SKU y fecha](../../examples/baseline-agent/eks-rates.us-east-1.json)

## Límites

El módulo administra un grupo On-Demand x86-64. El consumidor gestiona networking, IAM de workloads, complementos, ingreso, autoscaler y observabilidad de aplicaciones. Antes de eliminar el clúster, aplica la desactivación de `deletion_protection_enabled` y valida la migración del estado y los workloads. El módulo permanece como candidato pendiente de revisión e integración en AWS.
