# Trabajo en este repositorio

- Este repo contiene módulos reutilizables de AWS bajo `aws/<recurso>/`.
- La persona responsable elige e inicializa el enfoque spec-driven. No imponer un framework ni generar su estructura por adelantado.
- El módulo recibe configuración del proyecto consumidor; no define proveedores configurados, backend, credenciales ni estado propio.
- Mantener valores predeterminados seguros, variables tipadas, validaciones, outputs y documentación breve de las limitaciones.
- Representar variantes mediante entradas y ejemplos; versionar mediante Git, sin duplicar módulos por versión o perfil.
- Modificar pruebas de comportamiento cuando cambie el módulo. `terraform test` utiliza exclusivamente proveedores simulados.
- Ejecutar `scripts/validate.sh` y `scripts/security.sh`. Las pruebas simuladas no acreditan un despliegue real en AWS.
- Mantener `module.yaml` y `audit-record.yaml` coherentes. Solo el arquitecto autoriza aprobación de producción; nunca inventar revisiones o evidencias.
