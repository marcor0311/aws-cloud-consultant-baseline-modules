# Amazon Cognito

Crea un grupo de usuarios con inicio de sesión por correo, contraseñas de 12 caracteres, MFA por aplicación, recuperación por correo verificado y protección contra borrado. Agrega un cliente web público con flujo de código OAuth, tokens de una hora y revocación.

| Perfil | Configuración | Ejemplo |
| --- | --- | --- |
| `web-app` | Usuarios creados por un administrador y cliente web. | [Terraform](examples/web-app/) |

| Entrada | Tipo | Valor predeterminado |
| --- | --- | --- |
| `name` | `string` | Obligatoria |
| `callback_urls` | `list(string)` | Obligatoria. HTTPS o `http://localhost`. |
| `logout_urls` | `list(string)` | `[]` |
| `mfa` | `string` | `OPTIONAL` |
| `self_sign_up` | `bool` | `false` |
| `deletion_protection` | `bool` | `true` |
| `tags` | `map(string)` | `{}` |

Salidas: `user_pool_id`, `user_pool_arn`, `issuer_url` y `client_id`.

Para usar la interfaz alojada de inicio de sesión, agrega un `aws_cognito_user_pool_domain` en el proyecto. El correo de verificación sale por defecto del remitente de Cognito, limitado a 50 mensajes diarios; para producción configura Amazon SES. Cambiar `name` o los atributos de inicio de sesión reemplaza el grupo y borra sus usuarios.

[Especificación del cambio](change-spec.md)
