#!/usr/bin/env nix-shell
#!nix-shell -i bash -I nixpkgs=channel:nixos-unstable-small ./shell.nix

set -eux
set -o pipefail

cd "$(dirname "$0")/base"
terraform init
terraform output -json \
  | jq .deploy_targets.value \
  | jq -cr '. as $input | keys | map(. as $name | { key: $name, value: $input[$name]}) | .[]'
