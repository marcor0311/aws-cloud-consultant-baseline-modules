---
name: maintain-baseline-module
description: Crea, modifica o retira módulos Terraform corporativos de AWS tras una selección del arquitecto, con especificación, compatibilidad, migración y pruebas.
---

# Cambiar el catálogo de baselines

Trabaja desde la selección del arquitecto y una rama autorizada. Completa la [plantilla SDD](../../../specs/baseline-module-agent/cambio-modulo.md). Consulta las skills y la documentación con Agent Toolkit for AWS y AWS MCP. Busca el recurso de Terraform con Terraform MCP en la versión del lockfile y confirma sus atributos con el esquema del proveedor instalado antes de fijar el contrato. Busca el `source` del módulo y sus referencias mediante GitHub MCP o Git para checkouts locales. Documenta alcance, limitaciones y efecto sobre el estado y los despliegues consumidores.

- **Alta.** Añade `aws/<módulo>` con entradas, salidas, ejemplos, pruebas simuladas y metadatos de consumo, costos y evidencias. Registra prerrequisitos regionales y controles. Verifica cómo se incorpora a CI.
- **Cambio.** Ajusta los perfiles y los ejemplos existentes. Revisa defaults, nombres de recursos Terraform, recursos reemplazables y migraciones. Compara costos bajo los mismos supuestos y actualiza el contrato de consumo.
- **Retiro.** Documenta motivo, sustituto y migración, revisa consumidores de referencias móviles y conserva las referencias históricas de Git. Retira el módulo del inventario activo junto con sus referencias de CI cuando corresponda. Una eliminación del módulo del catálogo no ejecuta `terraform destroy`.

Valida los perfiles afectados con `$validate-baseline-emulator` y entrega el resultado a `$review-baseline-change` con la especificación, la selección, el impacto y las limitaciones.
