#!/usr/bin/env nix-shell
#!nix-shell -i bash ./shell.nix
# shellcheck shell=bash

set -eux
set -o pipefail

scratch=$(mktemp -d -t tmp.XXXXXXXXXX)
function finish {
	  rm -rf "$scratch"
  }
trap finish EXIT


machines() (
  "$(dirname "$0")/terraform/enumerate-servers.sh"
)

mkdir "$scratch/machines"

networkentry() (
  name=$1
  ip=$2

  cat <<EOF
  "$name" = {
    deployment = {
      targetHost = "$ip";
      targetUser = "root";
      substituteOnDestination = true;
    };
    imports = [
      ../nixops/modules
      ./machines/$name.expr.nix
      ./machines/$name.system.nix
    ];
  };
EOF
)

sshwrap() (
  ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile="$scratch/known_hosts" \
    -o BatchMode=yes \
    -o IdentitiesOnly=yes \
    -i "$SSH_IDENTITY_FILE" \
    "$@"
)

cfg_for_provisioner() (
  local provisioner=$1
  local name=$2
  local ip=$3

  case "$provisioner" in
    "metal")
      cfg_for_metal "$name" "$ip"
      ;;
    "nixos-install")
      cfg_for_nixos_install "$name" "$ip"
      ;;
    *)
      echo "Failed: no such provisioner: $provisioner"
      exit 1
      ;;
  esac
)

cfg_for_metal() (
  local name=$1
  local ip=$2
  sshwrap "root@$ip" -- cat /etc/nixos/packet/system.nix > "$scratch/machines/${name}.system.nix"
)

cfg_for_nixos_install() (
  local name=$1
  local ip=$2

  mkdir -p "$scratch/machines/${name}"
  sshwrap "root@$ip" -- cat /etc/nixos/configuration.nix > "$scratch/machines/${name}/configuration.nix"
  sshwrap "root@$ip" -- cat /etc/nixos/hardware-configuration.nix > "$scratch/machines/${name}/hardware-configuration.nix"
  printf '{ imports = [ %s ]; }' "./${name}/configuration.nix" >  "$scratch/machines/${name}.system.nix"
)

import_machine() (
  local machine=$1

  local name
  name="$(jq -r .key <<<"$machine")"

  # XXX: don't care about eval-1 for now, since it cannot be deployed to
  # (it is EFI-boot, but the config does not reflect that)
  [ "$name" = "ofborg-evaluator-1" ] && return

  local ip
  ip="$(jq -r .value.ip <<<"$machine")"
  local provisioner
  provisioner=$(jq -r .value.provisioner <<<"$machine")
  jq -r .value.expression <<<"$machine"
  jq -r .value.expression <<<"$machine" > "$scratch/machines/${name}.expr.nix"
  if cfg_for_provisioner "$provisioner" "$name" "$ip"; then
    networkentry "$name" "$ip" >> "$scratch/default.nix"
  fi
)

cat <<EOF > "$scratch/default.nix"
{
  network = {
    pkgs =
      let
        sources = import ../nix/sources.nix;
      in
      import sources.nixpkgs {
        config = {
          allowUnfree = true;
        };
      };
    nixConfig = {
      builders = "";
      experimental-features = "nix-command";
    };
  };

EOF

machines | while read -r machine; do
   import_machine "$machine" < /dev/null
done

echo "}" >> "$scratch/default.nix"

git rm -rf ./morph-network
rm -rf ./morph-network

mv "$scratch" ./morph-network
git add morph-network
