# Integraciones de la sesión de Codex

Abre Codex desde la raíz de Baseline Modules como proyecto de confianza. La configuración del proyecto desactiva la búsqueda web. El agente obtiene evidencia por MCP, SDK y archivos locales. Empieza por GitHub MCP para el issue, AWS MCP para documentación y disponibilidad, y Terraform MCP para el contrato del proveedor en la versión del lockfile.

## Conexiones del proyecto

AWS MCP público ya está habilitado y permite buscar documentación y skills sin credenciales. Terraform MCP usa un binario oficial fijado a la versión `1.4.1`, con el toolset `registry`. Instálalo en `.tools/` con Python 3.11 o superior. El instalador verifica el SHA-256 antes de habilitar el binario.

```sh
python3 scripts/setup_terraform_mcp.py
```

El proyecto incluye el bloque de conexión en `.codex/config.toml`. El conector GitHub de Codex puede compartir la sesión autenticada del usuario. Para tareas que requieran las capacidades autenticadas del Agent Toolkit for AWS, instala `aws-core` con la identidad de AWS autorizada.

```sh
codex plugin marketplace add aws/agent-toolkit-for-aws
```

Los bloques de AWS Pricing MCP, AWS DevOps Agent y AWS Security Agent quedan disponibles para activarlos con `enabled = true` después de configurar sus prerrequisitos. Usa identidad y configuración local para credenciales. El ejemplo DevOps usa `us-east-1`. Si el Agent Space está en otra región, cambia tanto el endpoint como `--region`. [Configuración de proyecto en Codex](https://developers.openai.com/plugins/build/plugins#enable-or-disable-a-plugin-for-a-repo)

| Integración | Configuración y verificación |
| --- | --- |
| GitHub MCP | Usa el conector de GitHub de Codex si está presente. La configuración local también admite un token en `BASELINE_GITHUB_TOKEN`. Lee el issue #19 y un manifiesto a una referencia exacta. Para publicar y solicitar revisión se requiere acceso al repo y autorización para el cambio. |
| AWS MCP | Usa `aws-core` para consultar documentación, capacidades y disponibilidad regional del recurso seleccionado. `baseline-aws-knowledge` expone estas herramientas públicas mediante un filtro de funciones de solo lectura. Las operaciones contra una cuenta requieren identidad AWS autorizada. |
| Terraform MCP | Consulta `search_provider_docs` con la versión del lockfile. Contrasta los campos con el esquema del proveedor instalado mediante `terraform providers schema -json`. |
| AWS Pricing MCP y Boto3 | Usa Pricing MCP para identificar SKU, unidad y región. Cotiza con `scripts/quote_aws.py --sdk` por `GetProducts`. Cuando falte la identidad AWS, usa la API regional pública de Price List Bulk. |
| AWS DevOps Agent | Conecta por SigV4 a un Agent Space habilitado y solicita una revisión de dependencias operativas y observabilidad del módulo. Guarda enlace, alcance y resultado. |
| AWS Security Agent | Usa el MCP para revisión defensiva del diseño o código en una cuenta autorizada. La revisión de código puede cargar archivos a un bucket de esa cuenta. Guarda el resultado y su alcance en la evidencia del cambio. |
| AWS Diagram as Code | Instala `awsdac` y renderiza `diagrams/baseline-piloto.yaml`. Confirma que los recursos y dependencias coincidan con Terraform y el contrato de consumo. |
| MCP del backend | Cuando el trabajo esté ligado a un expediente, usa el MCP de Consultant Agent si expone el registro de tiempos y entregas para el trabajo de baselines. El backend conserva la responsabilidad sobre LangGraph y PostgreSQL. |

Al iniciar una tarea, registra cuáles herramientas respondieron y cuáles requieren cuenta, permisos o configuración. Conserva esa evidencia con el PR si afecta el resultado presentado. Cuando una verificación no tenga evidencia por MCP, SDK o archivos locales, queda pendiente. Las consultas del catálogo y las cotizaciones a partir de Price List Bulk se pueden hacer sin un Agent Space.

Para contrastar un escenario con AWS Pricing Calculator, toma `aws_usage_type` y `aws_operation` de la cotización de cada SKU y confirma que correspondan a la dimensión de facturación. Envía las cantidades mensuales a `GetUsageLinesEstimatedCost` con tarifas públicas `BEFORE_DISCOUNTS`, cuando el perfil de facturación lo permita. Documenta partidas rechazadas y diferencias de tramos o franquicias respecto al cálculo local. [GetUsageLinesEstimatedCost](https://docs.aws.amazon.com/cli/latest/reference/bcm-pricing-calculator/get-usage-lines-estimated-cost.html)

Referencias oficiales de [Agent Toolkit for AWS](https://docs.aws.amazon.com/agent-toolkit/latest/userguide/quick-start.html), [GitHub MCP](https://github.com/github/github-mcp-server), [Terraform MCP](https://developer.hashicorp.com/terraform/mcp-server/deploy/local), [AWS Pricing MCP](https://awslabs.github.io/mcp/servers/aws-pricing-mcp-server), [DevOps Agent](https://docs.aws.amazon.com/devopsagent/latest/userguide/connecting-to-devops-agent-remote-servers-authentication-and-security.html), [Security Agent](https://docs.aws.amazon.com/securityagent/latest/userguide/code-review-ide-integration.html) y [Diagram as Code](https://github.com/awslabs/diagram-as-code).

## Claude Code

El agente funciona igual desde Claude Code con la configuración del repo:

| Pieza | Codex | Claude Code |
| --- | --- | --- |
| Instrucciones | `AGENTS.md` | `CLAUDE.md`, que importa `AGENTS.md` |
| Skills | `.agents/skills/` (`$nombre`) | `.claude/skills/`, enlace a la misma carpeta (`/nombre`) |
| MCP | `.codex/config.toml` | `.mcp.json` (Terraform MCP y AWS Knowledge MCP) |
| Hook de verificación | `.codex/hooks.json` | `Stop` en `.claude/settings.json` |
| Límite de gasto | `multi_agent = false` | `permissions.deny: ["Agent"]` |
| Esfuerzo | `model_reasoning_effort = "low"` | `effortLevel: "low"` |
| Modelo | Elección de cada usuario | Elección de cada usuario |
| AWS Knowledge MCP | `enabled_tools` con 5 herramientas de conocimiento | `deny` de `run_script`, `get_presigned_url` y `get_tasks` |
| Búsqueda web | `web_search = "disabled"` | `permissions.deny: ["WebSearch", "WebFetch"]` |

1. Instala Terraform MCP en `.tools/` como se indica arriba; ambos agentes usan el mismo binario.
2. Abre el repo en Claude Code y aprueba los servidores de `.mcp.json` cuando lo solicite.
3. Para las capacidades autenticadas de AWS, instala Agent Toolkit for AWS: `/plugin install aws-core@claude-plugins-official` y luego `/reload-plugins`.
4. Para GitHub usa `gh` autenticado. Los servidores opcionales (Pricing, DevOps y Security) se agregan a `.mcp.json` con los mismos comandos de `.codex/config.toml` cuando sus prerrequisitos estén listos.
