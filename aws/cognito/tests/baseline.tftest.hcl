mock_provider "aws" {
  mock_resource "aws_cognito_user_pool" {
    defaults = { endpoint = "cognito-idp.us-east-1.amazonaws.com/us-east-1_AbCdEfGhI" }
  }
}

variables {
  name          = "poc-users"
  callback_urls = ["https://app.example.com/callback"]
}

run "secure_defaults" {
  command = apply

  assert {
    condition     = aws_cognito_user_pool.this.password_policy[0].minimum_length == 12 && aws_cognito_user_pool.this.password_policy[0].require_symbols
    error_message = "Contraseñas de al menos 12 caracteres con símbolos."
  }

  assert {
    condition     = aws_cognito_user_pool.this.mfa_configuration == "OPTIONAL" && aws_cognito_user_pool.this.software_token_mfa_configuration[0].enabled
    error_message = "MFA por aplicación disponible para cada usuario."
  }

  assert {
    condition     = aws_cognito_user_pool.this.admin_create_user_config[0].allow_admin_create_user_only && aws_cognito_user_pool.this.deletion_protection == "ACTIVE"
    error_message = "Sin registro libre y con protección contra borrado."
  }

  assert {
    condition     = aws_cognito_user_pool_client.this.generate_secret == false && aws_cognito_user_pool_client.this.allowed_oauth_flows == toset(["code"]) && aws_cognito_user_pool_client.this.prevent_user_existence_errors == "ENABLED"
    error_message = "Cliente público con flujo de código que no revela si un usuario existe."
  }

  assert {
    condition     = !contains(tolist(aws_cognito_user_pool_client.this.explicit_auth_flows), "ALLOW_USER_PASSWORD_AUTH")
    error_message = "No se permite enviar la contraseña en claro al API de autenticación."
  }

  assert {
    condition     = output.issuer_url == "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_AbCdEfGhI"
    error_message = "El emisor OIDC usa HTTPS."
  }
}

run "rejects_http_callback" {
  command = plan

  variables {
    callback_urls = ["http://app.example.com/callback"]
  }

  expect_failures = [var.callback_urls]
}
