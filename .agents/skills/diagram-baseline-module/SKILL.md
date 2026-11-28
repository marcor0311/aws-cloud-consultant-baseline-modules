---
name: diagram-baseline-module
description: Genera o actualiza el diagrama de alcance de un módulo o selección de baselines con AWS Diagram as Code, verificado contra Terraform y el contrato de consumo.
---

# Diagramar el alcance de un baseline

Úsala cuando una selección o un cambio de módulo altere recursos o dependencias que el arquitecto o el consumidor deban entender.

1. Lee `aws/<módulo>/main.tf`, `module.yaml` y el ejemplo del perfil. Separa los recursos que crea el módulo de las dependencias que aporta el consumidor (claves KMS, funciones, VPC, certificados).
2. Copia la estructura de `diagrams/baseline-piloto.yaml`: un `AWS::Diagram::HorizontalStack` para los recursos del módulo y otro para las dependencias. Usa tipos CloudFormation reales para los íconos (`AWS::S3::Bucket`, `AWS::KMS`) y títulos en español que nombren el control relevante, por ejemplo "DynamoDB con PITR". Guarda el archivo como `diagrams/baseline-<módulo o selección>.yaml`.
3. Agrega un `Link` por cada relación que exista en Terraform o en las entradas del módulo. No dibujes relaciones que el código no crea ni exige.
4. Renderiza con `awsdac diagrams/<archivo>.yaml -o /tmp/<archivo>.png` y revisa la imagen. Si `awsdac` no está instalado, entrega el YAML y deja el renderizado como pendiente.
5. Enlaza el YAML desde la lista de `$select-baseline-modules` o desde el PR de `$review-baseline-change`. El YAML es la fuente editable y la imagen no se versiona.
