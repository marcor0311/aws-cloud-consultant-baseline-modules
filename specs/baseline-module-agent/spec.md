# Especificación del Baseline Module Agent

La sesión de Codex se ejecuta en `aws-cloud-consultant-baseline-modules`. Implementa el cuadro de baselines del [issue #19](https://github.com/marcor0311/aws-cloud-consultant-agent/issues/19). GitHub es la interfaz con el arquitecto y el agente consumidor. Estos pueden consultar la ruta, el código, la documentación, los perfiles y el estado de aprobación en una referencia Git concreta.

## Consulta y selección

**Entrada.** URL del issue o requisitos de consumo, región de la carga, controles que debe cumplir y supuestos de uso. Si hay varios perfiles, se presentan las diferencias que afectan configuración, precio o validación. Los datos faltantes se indican junto al requisito o partida correspondiente.

**Lista previa al PR.** Por opción, entregar requisito cubierto, módulo y perfil, versión candidata o aprobada, commit verificable, ejemplo Terraform, entradas obligatorias, dependencias, controles, límites, evidencia y estado de revisión. Incluir un diagrama de alcance del módulo cuando ayude a explicar dependencias. Exponer las opciones en Markdown y conservar la estimación en JSON. El arquitecto puede seleccionar versiones utilizables y solicitar altas o ajustes para las capacidades faltantes. Para usar una versión en producción, exigir evidencia verificable de aprobación del arquitecto para esa revisión.

**Costo.** Estimar cargos mensuales por opción y por selección, con región, moneda, cantidad, unidad, tarifas, fuente y fecha. Incluir dependencias facturables y contabilizar una dependencia compartida una sola vez por instancia real. Separar subtotales conocidos de partidas pendientes. Los cálculos del piloto usan tarifas públicas de AWS y uso mensual explícito. Un escenario puede tener un solo perfil por módulo. Comparar perfiles mediante escenarios separados.

## Cambios del catálogo

1. Identificar la diferencia entre lo que el consumidor necesita y lo que ofrece el catálogo. Presentar las opciones y registrar la elección antes de abrir un PR de baselines.
2. Completar la [especificación de cambio](cambio-modulo.md). Buscar consumidores accesibles por referencias Git y revisar entradas, salidas, comportamiento, seguridad, costo y efecto sobre el estado Terraform. Documentar migración o retiro y el alcance de la búsqueda.
3. Implementar el cambio con ejemplos, pruebas, documentación, análisis de seguridad y estimación actualizada. Para altas o bajas, comprobar que CI y los comandos de validación cubran el nuevo inventario. Conservar el historial Git de los consumidores fijados a versiones anteriores.
4. Preparar el PR de baselines con el issue de origen, elección del arquitecto, diff del contrato, evidencia, cambio de costo, limitaciones y plan de migración. Solicitar la revisión del arquitecto. Verificar aprobación y checks para la revisión exacta antes de anunciar la referencia como aprobada. La aprobación de producción se registra explícitamente por el arquitecto y se vincula a la revisión autorizada.

## Criterios de aceptación

- Con los tres módulos iniciales, el agente identifica los seis perfiles, sus ejemplos y el estado real de revisión. Una opción en borrador se muestra como candidata, con una referencia para inspección.
- El arquitecto puede comparar opciones y obtener el total de una selección sin sumar perfiles alternativos ni duplicar dependencias. Se muestran un caso con tarifas trazables y un caso con estimación parcial.
- `shopping-list` produce la comparación en Markdown y JSON con el mismo cálculo. El JSON incluye elecciones compatibles con el consumidor para candidatos con referencia Git publicable. Una vista previa o una aprobación pendiente de verificar queda identificada junto al perfil correspondiente.
- Una solicitud de cambio incompatible incluye consumidores accesibles, efecto sobre estado o reemplazo y migración. El PR conserva la elección previa, las pruebas y la revisión humana.
- Una herramienta pendiente o una prueba fallida queda visible en la evidencia. El agente nunca convierte una comprobación local en una aprobación de producción.
