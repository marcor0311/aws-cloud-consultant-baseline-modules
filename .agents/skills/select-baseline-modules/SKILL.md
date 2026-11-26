---
name: select-baseline-modules
description: Consulta y audita el catálogo AWS de este repositorio y presenta módulos y perfiles comparables al arquitecto antes de un PR de baselines.
---

# Elegir módulos del catálogo

1. Lee el issue autorizado por GitHub MCP o toma los requisitos que entregue el arquitecto. Extrae capacidad, región, aislamiento, resiliencia, seguridad y uso esperado. Usa AWS MCP para comprobar documentación y disponibilidad regional, y Terraform MCP para verificar el recurso con la versión fijada en el lockfile. Registra los datos pendientes si alguna consulta falla.
2. Ejecuta `python scripts/baseline.py catalog` con las dependencias de la guía. Si el consumidor trabaja desde GitHub, inspecciona `aws/<módulo>/module.yaml`, `audit-record.yaml`, README y ejemplo en el mismo commit. Usa `catalog --ref COMMIT` para reconstruir una revisión local. Contrasta los controles con Terraform, y la revisión y los checks con GitHub.
3. Usa `python scripts/baseline.py shopping-list USO.json TARIFAS.json --format markdown` para generar la comparación con los supuestos del consumidor. Conserva también el JSON, que incluye las partidas, sus fuentes y las capacidades faltantes. Consulta `$estimate-baseline-cost` para comparar escenarios con uso equivalente.
4. Devuelve la lista antes de preparar un PR. Para una opción existente, vuelve a generar la lista con `--ref COMMIT` y verifica el `source` Terraform en GitHub MCP. El JSON entrega la selección en el contrato de Arquitectura cuando el candidato está publicado y es verificable. Para producción, verifica por separado aprobación del arquitecto del commit exacto. Si solicita un cambio de catálogo, conserva la selección y el issue de origen como entradas de `$maintain-baseline-module`.

El formato de entrega, los comandos y el ejemplo están en [la guía del agente](../../../docs/agente/README.md).
