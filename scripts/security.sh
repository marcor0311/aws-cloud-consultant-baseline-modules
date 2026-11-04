#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
scanner="${TRIVY_BIN:-trivy}"
if ! command -v "$scanner" >/dev/null 2>&1; then
  echo "Instala Trivy 0.76.1 o ejecuta el job de seguridad de GitHub Actions." >&2
  exit 1
fi
scanner="$(command -v "$scanner")"
for module in "$repo_root"/aws/*; do
  [[ -d "$module" ]] || continue
  example_count=0
  for example in "$module"/examples/*; do
    [[ -d "$example" ]] || continue
    if [[ ! -f "$example/terraform.tfvars.example" ]]; then
      echo "Faltan los valores del ejemplo: $example/terraform.tfvars.example" >&2
      exit 1
    fi
    (
      cd "$example"
      "$scanner" config --disable-telemetry --misconfig-scanners terraform \
        --tf-vars terraform.tfvars.example --severity HIGH,CRITICAL \
        --exit-code 1 --skip-dirs '**/.terraform' .
    )
    example_count=$((example_count + 1))
  done
  if [[ $example_count -eq 0 ]]; then
    echo "El módulo $module necesita al menos un ejemplo para el análisis de seguridad." >&2
    exit 1
  fi
done
