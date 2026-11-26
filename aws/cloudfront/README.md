# CloudFront · distribución HTTPS para S3 privado

Crea una distribución de solo lectura para el endpoint REST regional de un bucket S3 privado. CloudFront firma las peticiones al origen con OAC y SigV4, redirige HTTP a HTTPS, usa el certificado administrado de su dominio y exige WAFv2 global y logs de acceso.

- **Entradas obligatorias:** `origin_domain_name`, `origin_bucket_arn`, `web_acl_arn`, `logging_bucket_domain` y `tags`.
- **Perfiles:** [regional](examples/regional/) usa `PriceClass_100` y [global](examples/global/) usa `PriceClass_All`. Son alternativas de cobertura para un mismo origen.
- **Outputs:** ID, dominio y declaración de política del origen.
- [Entradas y validaciones](variables.tf) · [Pruebas](tests/baseline.tftest.hcl) · [Auditoría](audit-record.yaml).

## Integración con S3

Conserva el bloqueo de acceso público. Incorpora `origin_policy_statement` en la política que ya administra el bucket, junto con sus controles existentes. La declaración concede `s3:GetObject` al principal de CloudFront condicionado al ARN exacto de la distribución. Si el bucket viene del módulo S3 de este repositorio, la composición de esa declaración debe entrar en la política que administra dicho módulo. Crear otra política Terraform para el mismo bucket provocaría conflicto de propiedad.

Si el origen usa SSE-KMS, autoriza el descifrado en la política de la clave con el principal de CloudFront y la condición del ARN de esta distribución. Usa un bucket de logs separado con ACL habilitadas para la entrega estándar legacy. Verifica la entrega de logs y el acceso HTTPS antes de dirigir tráfico de producción.

## Costo aproximado

La lista de selección usa cargos públicos bajo demanda para **Estados Unidos**, no la región del bucket como zona de facturación. Con 1 millón de solicitudes HTTPS GET/HEAD y 100 GB de salida en Estados Unidos, el subtotal es **USD 9,50 al mes** antes de franquicias y descuentos. WAF, solicitudes al origen, almacenamiento de logs y KMS quedan pendientes de dimensionar. La porción en otros mercados también queda pendiente para ambos perfiles hasta conocer la distribución de tráfico.

Desde la raíz del repositorio:

```sh
python scripts/baseline.py shopping-list examples/baseline-agent/cloudfront-usage.json examples/baseline-agent/cloudfront-rates.us-east-1.json --format markdown
```

[Tarifas por SKU](../../examples/baseline-agent/cloudfront-rates.us-east-1.json)
