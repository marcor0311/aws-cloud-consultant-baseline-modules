# API Gateway · HTTP API autenticado

Crea un HTTP API con integración Lambda, rutas autenticadas, permisos de invocación limitados a su API y stage, logs cifrados y límites de solicitudes.

- **Entradas obligatorias:** `name`, `lambda_function_arn`, `log_kms_key_arn` y `tags`.
- **Autenticación:** IAM por defecto; admite JWT con emisor HTTPS, audiencias y scopes. No permite `NONE`.
- **Límites predeterminados:** 100 solicitudes/s, ráfaga de 200 y logs por 90 días.
- **Rutas:** `$default` por defecto; un conjunto de rutas explícitas puede apuntar a la misma función.
- **Outputs:** `api_id`, `api_endpoint`, `execution_arn` y `access_log_group_arn`.
- [Entradas y validaciones](variables.tf) · [IAM](examples/iam/) · [JWT](examples/jwt/) · [Pruebas](tests/baseline.tftest.hcl).

La función Lambda debe existir en la cuenta/región del API. La clave KMS existente debe autorizar al principal regional `logs.<region>.amazonaws.com` con el contexto de cifrado del grupo de logs. El módulo no modifica su política. Para JWT, el emisor debe ofrecer su descubrimiento OIDC/JWKS y emitir tokens para la audiencia configurada. Exigir scopes para endpoints que requieran autorización funcional, además de autenticar el token.

Las llamadas IAM deben firmarse con SigV4. Los límites dependen de las cuotas regionales y compartidas de la cuenta; no garantizan capacidad. El API publica un endpoint regional autenticado; no equivale a una API privada. No incluye código Lambda, REST APIs, WAF, dominios propios ni CORS. El módulo está pendiente de revisión y validación en AWS.
