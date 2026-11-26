---
name: review-baseline-change
description: Revisa cambios de módulos de baselines, reúne evidencias de Terraform y seguridad y prepara el PR que debe aprobar el Cloud Solutions Architect.
---

# Revisar y entregar el cambio

1. Revisa la selección del arquitecto, la especificación y los cambios en dependencias, seguridad y costo. Confirma el resultado real de `scripts/validate.sh` y `scripts/security.sh`. Revisa ejemplos y `audit-record.yaml`. Si una herramienta está pendiente, cita el motivo y deja la comprobación pendiente.
2. Usa los MCPs de AWS DevOps Agent y AWS Security Agent para revisar operabilidad, dependencias y seguridad si hay un Agent Space y acceso autorizados. Conserva el identificador o enlace de revisión y su alcance. Registra el estado pendiente de una revisión que no se ejecutó. Usa AWS Diagram as Code cuando cambien recursos o relaciones que el consumidor deba entender.
3. Prepara el PR de baselines con issue, selección, contrato, impacto, costo, migración y evidencias. Usa GitHub MCP para publicar y solicitar revisión cuando se autorice. Comprueba los checks y la aprobación del arquitecto sobre la revisión exacta. No conviertas una opinión, la integración del PR ni una prueba simulada en aprobación de producción.
4. Devuelve al consumidor el módulo, perfil, `source` fijado a la referencia aprobada, enlaces al PR y evidencia, y supuestos de costo. Registra tiempos y handoffs en el MCP del backend cuando el trabajo esté ligado al expediente y exista el contrato operativo para baselines.
