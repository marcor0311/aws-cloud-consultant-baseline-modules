---
name: estimate-baseline-cost
description: Estima y compara el costo mensual aproximado de módulos Terraform AWS, sus perfiles y dependencias con uso, tarifas y fuentes verificables.
---

# Estimar un baseline

1. Define la región, moneda, perfil, unidades consumidas por mes y supuestos del escenario. Identifica los cargos del módulo y del consumidor, incluidos cifrado, logs, transferencia y dependencias cuando apliquen. Para dependencias compartidas, usa un solo grupo de uso que represente las instancias o el consumo incremental real.
2. Usa AWS Pricing MCP para descubrir la dimensión de cobro. Confirma servicio, región de la carga, SKU, unidad y tramos. Cotiza con `python scripts/quote_aws.py SELECTORES.json --sdk` mediante Boto3. Si no hay perfil AWS, usa el catálogo regional público de AWS Price List o un archivo de esa API con procedencia verificable. Si el SKU es ambiguo o falta la tarifa, deja esa partida pendiente.
3. Ejecuta `python scripts/baseline.py estimate USO.json TARIFAS.json`. Conserva el desglose, las fuentes y los rubros pendientes. Compara perfiles en escenarios independientes. Usa cero solo si el supuesto explícito confirma que no habrá consumo. Los descuentos, impuestos, créditos y cargos de otros entornos se indican aparte.
4. Para la entrega a FinOps, contrasta el escenario con AWS Pricing Calculator cuando haya identidad AWS y perfil de facturación: toma `aws_usage_type` y `aws_operation` de cada SKU cotizado, envía las cantidades mensuales a `GetUsageLinesEstimatedCost` con tarifas `BEFORE_DISCOUNTS` y documenta las partidas rechazadas o las diferencias de tramos. Sin identidad AWS, deja el contraste pendiente; no lo omitas en silencio.
5. Devuelve el costo de cada opción y la selección con fecha y moneda. Si faltan cantidades o tarifas, muestra el subtotal conocido y lo pendiente. Para incorporar otro recurso, añade sus dimensiones en `module.yaml` y contrasta qué se factura mediante AWS MCP.

Consulta [la guía del agente](../../../docs/agente/README.md#estimar-un-escenario) para el contrato de datos y los comandos.
