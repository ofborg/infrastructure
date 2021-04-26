#!/usr/bin/env nix-shell
#!nix-shell -i bash ./shell.nix

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
  provisioner=$1
  ip=$2

  case "$provisioner" in
    "metal")
      cfg_for_metal "$ip"
      ;;
    *)
      echo "Failed: no such provisioner: $provisioner"
      exit 1
      ;;
  esac
)

cfg_for_metal() (
  sshwrap "root@$ip" -- cat /etc/nixos/packet/system.nix > "$scratch/machines/${name}.system.nix"
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

machines | while read machine; do
   (
        name="$(jq -r .key <<<"$machine")"
        ip=$(jq -r .value.ip <<<"$machine")
        provisioner=$(jq -r .value.provisioner <<<"$machine")
        jq -r .value.expression <<<"$machine"
        jq -r .value.expression <<<"$machine" > "$scratch/machines/${name}.expr.nix"
        if cfg_for_provisioner "$provisioner" "$ip"; then
          networkentry "$name" "$ip" >> "$scratch/default.nix"
        fi
   ) < /dev/null
done

echo "}" >> "$scratch/default.nix"

git rm -rf ./morph-network
rm -rf ./morph-network

mv "$scratch" ./morph-network
git add morph-network
