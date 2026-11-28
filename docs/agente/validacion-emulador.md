# Validación local con AWS Emulator

La CI y la skill `validate-baseline-emulator` ejecutan plan, apply, una comprobación y destroy de cada perfil afectado contra [AWS Emulator](https://docs.aws.amazon.com/emulator/latest/userguide/getting-started-agent.html) 1.0.385, fijado en `scripts/emulator/Dockerfile`. Requiere Docker, Terraform 1.14.8 y Python 3.10 o superior.

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r scripts/requirements-baseline.txt
docker build --platform linux/amd64 -t baseline-poc-aws-emulator:1.0.385 scripts/emulator
.venv/bin/python scripts/test_emulator.py --case s3/default --evidence reports/s3-default.json
```

## Cobertura

| Módulo | Comprobación | Estado |
| --- | --- | --- |
| S3 | Funcional (objetos, cifrado, etiquetas) | Pasa |
| DynamoDB | Funcional (lectura y escritura) | Pasa |
| CloudFront | Convergencia del estado Terraform | Pasa |
| API Gateway | — | No aplica: `terraform apply` no termina en el emulador |
| EKS | — | No aplica: el ejemplo lee subredes reales con data sources |

La CI excluye API Gateway y EKS del job del emulador y el check **Validación de baselines** los reporta como "no aplica". Para incorporarlos se necesita un adaptador funcional o fixtures de red emulados.

En un PR, `scripts/select_emulator_cases.py` compara HEAD con la rama base y selecciona los perfiles afectados. Un cambio compartido de validación incluye S3 y DynamoDB como muestra, y la ejecución manual del workflow valida todo el catálogo emulable.

Adjunta al PR la evidencia JSON de cada caso, con la versión del emulador y sus `limitations`. El emulador usa una sola cuenta y región en memoria; los resultados de IAM y KMS no demuestran la aplicación de políticas en AWS.
