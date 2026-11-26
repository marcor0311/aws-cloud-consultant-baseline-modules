# Alta de EKS · candidato 0.1.0

| Campo | Decisión del piloto |
| --- | --- |
| Origen y elección | Se pidió EKS para probar el agente de Baseline Modules del [issue #19](https://github.com/marcor0311/aws-cloud-consultant-agent/issues/19). Se presentan dos perfiles para revisión del arquitecto. |
| Alcance | Alta de `aws/eks`. Clúster privado, un grupo EC2 administrado, logs y acceso del administrador. |
| Contrato | VPC, subredes, roles, claves KMS y versión Kubernetes son entradas. El módulo devuelve identidad del clúster, endpoint, CA y grupo de nodos. |
| Aceptación | Formato, ejemplos y pruebas simuladas verifican API privada, acceso explícito, logs, cifrado, IMDSv2, capacidad y rechazo de subredes incompatibles. Trivy analiza ambos perfiles. |
| Impacto | Alta con ruta nueva y referencia Git propia. La composición actual del repositorio de Consultant Agent y la plantilla se revisaron como consumidores inmediatos. |
| Costo | Se cotizan el control plane, los nodos, los discos, la ingestión y retención de logs y KMS. La red queda como partida pendiente hasta conocer topología y tráfico. |
| Evidencia | [Auditoría del módulo](../aws/eks/audit-record.yaml), [ejemplos](../aws/eks/README.md) y [diagrama editable](../diagrams/baseline-eks.yaml). |

La selección para revisión usa el alcance y los supuestos del [README de EKS](../aws/eks/README.md). El arquitecto debe revisar el dimensionamiento, la red, las políticas IAM y KMS y el resultado de una integración en AWS antes de aprobar el candidato para producción.
