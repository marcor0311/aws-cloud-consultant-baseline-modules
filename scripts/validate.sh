#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [[ $# -gt 1 ]]; then
  echo "Uso: scripts/validate.sh [--list|nombre-del-módulo]" >&2
  exit 2
fi

modules=()
for module_dir in aws/*; do
  [[ -d "$module_dir" ]] || continue
  module="${module_dir##*/}"
  if [[ ! "$module" =~ ^[a-z][a-z0-9-]+$ || ! -f "$module_dir/module.yaml" ]]; then
    echo "Módulo sin identificador válido o manifiesto: $module_dir" >&2
    exit 2
  fi
  modules+=("$module")
done
if [[ -z "${modules[*]-}" ]]; then
  echo "No se encontraron módulos AWS." >&2
  exit 2
fi

if [[ "${1-}" == --list ]]; then
  printf '%s\n' "${modules[@]}"
  exit 0
fi
if [[ $# -eq 1 ]]; then
  if [[ ! "$1" =~ ^[a-z][a-z0-9-]+$ || ! -f "aws/$1/module.yaml" ]]; then
    echo "Módulo desconocido: $1. Consulta scripts/validate.sh --list." >&2
    exit 2
  fi
  modules=("$1")
fi

export TF_IN_AUTOMATION=1
terraform fmt -check -recursive
mkdir -p reports
for module in "${modules[@]}"; do
  module_dir="aws/$module"
  terraform -chdir="$module_dir" init -backend=false -input=false -lockfile=readonly
  terraform -chdir="$module_dir" validate -no-color
  terraform -chdir="$module_dir" test -no-color 2>&1 | tee "reports/$module.tests.log"
  for example in "$module_dir"/examples/*; do
    [[ -d "$example" ]] || continue
    terraform -chdir="$example" init -backend=false -input=false -lockfile=readonly
    terraform -chdir="$example" validate -no-color
  done
done
