# Agente de Baseline Modules

Desde la raíz del repositorio, inicia Codex y pide `$select-baseline-modules` con el issue o los requisitos del consumidor. Por ejemplo:

> Necesito almacenamiento privado con historial, una tabla NoSQL con recuperación y una API HTTP autenticada en `us-east-1`. Compara los perfiles, estima el costo con el uso que te paso y muéstrame la lista antes de preparar un cambio de catálogo.

El arquitecto recibe una fila por alternativa, con el requisito, perfil, estado y referencia Git, contrato Terraform, dependencias, controles, límites, enlaces de evidencia y estimación. Para crear, modificar o retirar un módulo a partir de la selección, usa `$maintain-baseline-module`. Para preparar el PR de baselines y reunir evidencias, usa `$review-baseline-change`.

[Configuración de integraciones](integraciones.md) · [Especificación SDD](../../specs/baseline-module-agent/spec.md) · [Ejemplo de entrega](piloto.md)

## Inspeccionar el catálogo

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r scripts/requirements-baseline.txt
python scripts/baseline.py catalog
python scripts/baseline.py catalog --ref HEAD
```

El primer comando de catálogo lee los archivos del árbol de trabajo. El segundo lee una revisión de Git y devuelve la referencia Terraform para inspección. El `source` es una referencia técnica y el estado viene del registro de auditoría. Verifica por GitHub MCP la aprobación del arquitecto para el commit antes de recomendarlo para producción.

El inventario se lee de `aws/*/module.yaml` y `audit-record.yaml`. Los perfiles agregan su ejemplo, aplicabilidad y dimensiones de costo. Las entradas obligatorias de un perfil complementan las del módulo. Los READMEs, `variables.tf` y `outputs.tf` documentan el contrato completo, incluidos defaults y limitaciones.

## Preparar la lista para el arquitecto

```sh
mkdir -p reports
python scripts/baseline.py shopping-list \
  examples/baseline-agent/usage.json examples/baseline-agent/rates.us-east-1.json \
  --format markdown > reports/seleccion.md
python scripts/baseline.py shopping-list \
  examples/baseline-agent/usage.json examples/baseline-agent/rates.us-east-1.json \
  > reports/seleccion.json
```

Puedes agregar `source_issue` y `gaps` al archivo de uso. Cada módulo del escenario admite `requirement` y `configuration` para describir su función y las entradas Terraform elegidas. El Markdown compara escenarios y explica el contrato de cada perfil. El JSON agrega el desglose de costos y un objeto `selection` con los campos que consume `BaselineSelection` del agente de Arquitectura.

El modo de trabajo local produce una vista previa. Para entregar una referencia fija, actualiza las referencias de `origin` y agrega `--ref COMMIT`. El exportador arma payloads `draft` cuando el commit aparece en las referencias locales del `origin` oficial y el registro de auditoría es coherente. Confirma el commit en GitHub MCP antes del handoff. Revisa la aprobación explícita para el commit exacto antes de emitir una selección de producción.

## Estimar un escenario

```sh
python scripts/baseline.py estimate \
  examples/baseline-agent/usage.json examples/baseline-agent/rates.us-east-1.json
```

- El archivo de uso declara región, moneda, supuestos, exclusiones y escenarios. Cada escenario selecciona un perfil por módulo y declara el uso mensual en las unidades de las tarifas. Una dependencia compartida va una vez en `shared_usage`, con la cantidad real de recursos o de consumo.
- El archivo de tarifas conserva servicio, SKU, unidad, tramos, origen y fecha de cada cotización. Las partidas con uso o tarifa pendiente producen un subtotal conocido y un estado `partial`. Usa cantidad cero cuando la partida no aplica y decláralo en los supuestos.
- Las líneas de una opción separan el cargo propio del módulo y el de sus dependencias. Para comparar escenarios, mantén constantes región, volumen y dependencias, salvo los cambios que corresponden al perfil elegido.

Renueva los SKU con el SDK cuando tengas un perfil autorizado. Si el perfil no está disponible, usa la API pública regional de AWS Price List. Para cambiar de región, identifica los SKU regionales mediante AWS Pricing MCP o Price List.

```sh
python scripts/quote_aws.py examples/baseline-agent/rates.us-east-1.json --sdk > rates-sdk.json
python scripts/quote_aws.py examples/baseline-agent/rates.us-east-1.json > rates-us-east-1.json
```

El SDK usa AWS Price List `GetProducts`, con endpoint en `us-east-1` y precios filtrados por la región del producto. Los precios de muestra son públicos y excluyen impuestos, descuentos, créditos y franquicias gratuitas. El uso y el alcance deben revisarse para cada consumidor. [AWS Price List](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/price-changes.html)

## Validar el agente y un cambio de módulo

```sh
python -m unittest discover -s tests
scripts/validate.sh --list
awsdac diagrams/baseline-piloto.yaml -o /tmp/baseline-piloto.png
scripts/validate.sh
scripts/security.sh
```

CI usa el mismo inventario para descubrir módulos, ejecutar pruebas Terraform por módulo y analizar sus ejemplos con Trivy. La comprobación `Validación de baselines` resume los resultados del inventario, las pruebas del agente, Terraform y seguridad. Es un nombre estable para las reglas de protección de `main` cuando se agregan o retiran módulos.

### Verificación al cerrar un turno

El hook `Stop` ejecuta `scripts/validate.sh` y `scripts/security.sh` cuando detecta cambios en `aws/` respecto del punto de partida en `main`, incluso si ya están en commits de la rama. Revisa todo el inventario para cubrir altas y retiros. Los resultados quedan en `reports/baseline-verifier.log`. Ante un fallo, el hook devuelve el diagnóstico al agente y evita bloquear indefinidamente el mismo turno.

Codex requiere abrir el repositorio como proyecto de confianza y revisar el hook en `/hooks`. El entorno del hook necesita Terraform y Trivy disponibles en PATH, o `TRIVY_BIN` para indicar el binario. Las pruebas usan el proveedor simulado del repositorio.
