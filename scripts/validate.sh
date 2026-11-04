#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
export TF_IN_AUTOMATION=1
terraform fmt -check -recursive
mkdir -p reports

if [[ $# -eq 0 ]]; then
  modules=(s3 dynamodb api-gateway)
else
  case "$1" in
    s3|dynamodb|api-gateway) modules=("$1") ;;
    *) echo "Uso: scripts/validate.sh [s3|dynamodb|api-gateway]" >&2; exit 2 ;;
  esac
fi

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
