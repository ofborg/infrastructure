#!/usr/bin/env nix
#! nix shell --inputs-from .# nixpkgs#bashInteractive nixpkgs#openssh nixpkgs#nix nixpkgs#jq --command bash

set -euo pipefail -x

targets=(
  root@208.83.1.145
  root@208.83.1.173
  root@208.83.1.181
  root@208.83.1.186
  root@208.83.1.175
)

path=$(nix flake metadata --json | jq -r '.path')

SSHOPTS=(
  "-o" "ControlMaster=auto"
  "-o" "ControlPath=~/.ssh/cm-%r@%h:%p"
  "-o" "ControlPersist=60m"
)

# Establish persistent connections
for target in "${targets[@]}"; do
  ssh "${SSHOPTS[@]}" -Nf "$target"
done

for target in "${targets[@]}"; do
  NIX_SSHOPTS="${SSHOPTS[*]}" nix copy --to "ssh://$target" "$path"
done

declare -A builds
for target in "${targets[@]}"; do
  ssh "${SSHOPTS[@]}" "$target" "darwin-rebuild build -L --flake $path" &
  builds["$target"]=$!
done

for target in "${!builds[@]}"; do
  wait "${builds["$target"]}" || {
    echo "Build failed on $target"
    exit 1
  }
done

for target in "${targets[@]}"; do
  ssh "${SSHOPTS[@]}" "$target" "darwin-rebuild switch -L --flake $path"
done

# Close the persistent connections
for target in "${targets[@]}"; do
  ssh "${SSHOPTS[@]}" -O exit "$target"
done
