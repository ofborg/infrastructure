#!/usr/bin/env nix-shell
#!nix-shell -i bash ../shell.nix
# shellcheck shell=bash

set -eux

scriptroot="$(dirname "$(realpath "$0")")"
NRHOSTS="$(ls "$scriptroot"/../morph-network/machines/*.expr.nix | wc -l)"

step() {
  host="$1"

  cat <<EOF
  - label: ":nixos: :broom: $host"
    concurrency_group: ofborg-infrastructure-gc
    concurrency: $NRHOSTS
    command:
      - ./enter-env.sh morph exec --on="$host" ./morph-network/default.nix nix-collect-garbage
    agents:
      ofborg-infrastructure: true
EOF
}

hosts="$(nix-instantiate -E --eval --json \
  "builtins.attrNames
    (builtins.removeAttrs
      (import "$scriptroot"/../morph-network/default.nix)
      [ \"network\" ])" \
  | jq -r '. | to_entries | map("\(.value)") | join(" ")')"

(
  echo "steps:"

  for host in $hosts; do
    step "$host"
  done
) | buildkite-agent pipeline upload
