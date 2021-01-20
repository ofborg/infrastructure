#!/usr/bin/env nix-shell
#!nix-shell -i bash ../shell.nix

set -eux
set -o pipefail

cd "$(dirname "$0")/base"
terraform init >&2
terraform output -json \
  | jq .deploy_targets.value \
  | jq -cr '. as $input | keys | map(. as $name | { key: $name, value: $input[$name]}) | .[]'
