---
name: validate-baseline-emulator
description: Valida perfiles de módulos de baselines con AWS Emulator (plan, apply, prueba funcional y destroy) y adjunta la evidencia al PR.
---

# Validar un perfil con AWS Emulator

Úsala después de `$maintain-baseline-module` y antes de `$review-baseline-change`, solo para los perfiles afectados.

1. Calcula los casos afectados con `python scripts/select_emulator_cases.py --base origin/main`. No valides perfiles que el selector no incluya.
2. Construye la imagen una vez por sesión: `docker build --platform linux/amd64 -t baseline-poc-aws-emulator:1.0.385 scripts/emulator`.
3. Corre un caso a la vez, en primer plano y sin polling: `python scripts/test_emulator.py --case <módulo>/<perfil> --evidence reports/<módulo>-<perfil>.json`. Revisa solo `status` y los pasos que no estén en `passed`.
4. S3 y DynamoDB tienen prueba funcional; CloudFront solo comprueba convergencia del estado. API Gateway y EKS no son emulables (ver [validación con emulador](../../../docs/agente/validacion-emulador.md)): repórtalos como "no aplica en emulador" con el motivo, no como aprobados.
5. Si un caso falla dos veces por la misma causa, detente y reporta el paso y el detalle. Adjunta la evidencia JSON y sus `limitations` al PR. Un resultado del emulador nunca equivale a una aprobación de producción.
