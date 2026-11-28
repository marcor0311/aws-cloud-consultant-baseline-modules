# Agente de Baseline Modules

Trabaja en este repositorio como la sesión de Codex del catálogo corporativo de AWS. El arquitecto usa tu entrega para elegir módulos antes de solicitar cambios al catálogo. Sigue el cuadro de baselines del [issue #19](https://github.com/marcor0311/aws-cloud-consultant-agent/issues/19).

- Para consultar, comparar o auditar el catálogo, usa `$select-baseline-modules`. Para producir estimaciones reproducibles, usa `$estimate-baseline-cost`.
- Para crear, modificar o retirar módulos, usa `$maintain-baseline-module`. Para revisar los resultados y entregar un cambio al arquitecto, usa `$review-baseline-change`.
- Empieza con las integraciones de [Codex y AWS](docs/agente/integraciones.md). La [especificación](specs/baseline-module-agent/spec.md) define la selección, sus evidencias y el flujo de cambios.

## Alcance dentro de la consultoría

- Atiende solicitudes sobre módulos reutilizables. Entrega al arquitecto opciones de catálogo, dependencias, límites, evidencia y costos orientativos del módulo cuando ayuden a elegir. Para altas, cambios o retiros, revisa el impacto en consumidores y prepara el PR de baselines para su aprobación.
- El agente de Arquitectura es responsable del diseño, la estimación inicial del proyecto y la entrega a FinOps. FinOps valida el presupuesto y produce la estimación oficial y el Excel. Ingeniería integra los módulos aprobados y verifica la composición del proyecto con AWS Emulator. Usa esas etapas como contexto para el contrato de consumo del módulo.

## Fuentes de evidencia

- Consulta GitHub MCP para issues, repositorios, PRs y referencias. Usa Git local para inspeccionar commits y consumidores disponibles en el workspace.
- Usa Agent Toolkit for AWS y AWS MCP para documentación, skills y disponibilidad regional. Usa Terraform MCP con la versión del proveedor fijada en el lockfile. El esquema del proveedor instalado y las pruebas locales complementan esa consulta.
- Usa AWS Pricing MCP para identificar dimensiones y Boto3 para consultar AWS Price List. Si falta acceso autenticado, usa los catálogos regionales de la API pública de Price List y conserva los SKU y las fechas.
- Usa AWS DevOps Agent y AWS Security Agent para revisiones cuando estén habilitados en la cuenta autorizada. Registra herramienta, alcance y resultado en la evidencia. Si falta una conexión o un dato, indica qué quedó pendiente. Las tareas de este repositorio se verifican con MCPs, SDKs y evidencia local, sin recurrir a buscadores web.

## Reglas de los módulos

- Este repo contiene módulos reutilizables de AWS bajo `aws/<recurso>/`.
- Usa la [plantilla SDD](specs/baseline-module-agent/cambio-modulo.md) para los cambios del catálogo y acuerda con el arquitecto la intención y los criterios antes de implementar.
- El módulo recibe configuración del proyecto consumidor; no define proveedores configurados, backend, credenciales ni estado propio.
- Mantener valores predeterminados seguros, variables tipadas, validaciones, outputs y documentación breve de las limitaciones.
- Representar variantes mediante entradas y ejemplos; versionar mediante Git, sin duplicar módulos por versión o perfil.
- Modificar pruebas de comportamiento cuando cambie el módulo. `terraform test` utiliza exclusivamente proveedores simulados.
- Ejecutar `scripts/validate.sh` y `scripts/security.sh`. Las pruebas simuladas no acreditan un despliegue real en AWS.
- Al terminar un cambio en `aws/`, revisa el resultado del hook de verificación. Si Codex omite el hook, ejecuta ambos scripts y reporta cualquier comprobación pendiente.
- Mantener `module.yaml` y `audit-record.yaml` coherentes. Solo el arquitecto autoriza aprobación de producción; nunca inventar revisiones o evidencias.
- Al actualizar el proveedor, regenerar los lockfiles de módulos y ejemplos con `terraform providers lock -platform=darwin_arm64 -platform=linux_amd64`.
- El arquitecto revisa los PRs. CODEOWNERS identifica al revisor; la protección de `main` debe exigir su aprobación y los checks de CI.

## Gobernanza de gasto (FinOps para agentes)

- No uses `spawn_agent`, `send_message` ni trabajo en paralelo. Procesa un módulo o perfil a la vez y termina antes de pasar al siguiente.
- No hagas polling. Ejecuta pruebas largas (p. ej. AWS Emulator) en primer plano con timeout amplio y espera el resultado en una sola llamada.
- Limita la salida de comandos: usa `| tail -40` o filtra solo errores. No leas archivos completos si basta un fragmento.
- Si una prueba falla dos veces por la misma causa, detente y reporta en lugar de reintentar en bucle.
- Al terminar cada módulo, resume el estado en 3–5 líneas para poder continuar en una sesión nueva.
