#!/usr/bin/env nix-shell
#!nix-shell -i bash ../shell.nix
# shellcheck shell=bash

set -eux

scriptroot="$(dirname "$(realpath "$0")")"
NRHOSTS="$(ls "$scriptroot"/../morph-network/machines/*.expr.nix | wc -l)"

step() {
  host="$1"

  cat <<EOF
  - block: ":rotating_light: Deploy $host with a reboot :rotating_light: "
    key: deploy-$host-confirm-reboot

  - label: ":nixos: reboot deploy $host"
    depends_on: deploy-$host-confirm-reboot
    key: deploy-$host-reboot
    concurrency_group: ofborg-infrastructure-individual-reboot
    concurrency: $NRHOSTS
    command:
      - ./build/clone.sh
      - ./enter-env.sh morph deploy ./morph-network/default.nix boot --on="$host" --reboot
    agents:
      ofborg-infrastructure: true

  - label: "Pushing secrets to $host after reboot"
    depends_on: deploy-$host-confirm-reboot
    concurrency_group: ofborg-infrastructure-individual-reboot
    concurrency: $NRHOSTS
    key: deploy-$host-reboot
    commands:
      - ./build/clone.sh
      - ./enter-env.sh morph upload-secrets ./morph-network/default.nix --on="$host"
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
