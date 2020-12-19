#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq


scratch=$(mktemp -d -t tmp.XXXXXXXXXX)
function finish {
	  rm -rf "$scratch"
  }
trap finish EXIT


machines() (
  cd "$(dirname "$0")/terraform"
  nix-shell --run "cd base; terraform output -json | jq .deploy_targets.value" \
	  | jq -cr '. as $input | keys | map(. as $name | { key: $name, value: $input[$name]}) | .[]'
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

cat <<EOF > "$scratch/default.nix"
{
  network = {
    pkgs = import <nixpkgs> {};
    nixConfig = {
      builders = "";
      experimental-features = "nix-command";
    };
  };

EOF

machines | while read machine; do
	name="$(jq -r .key <<<"$machine")"
	ip=$(jq -r .value.ip <<<"$machine")
	jq -r .value.expression <<<"$machine" > "$scratch/machines/${name}.expr.nix"
  	ssh "root@$ip" -- cat /etc/nixos/packet/system.nix > "$scratch/machines/${name}.system.nix"

        networkentry "$name" "$ip" >> "$scratch/default.nix"
done

echo "}" >> "$scratch/default.nix"

rm -rf ./morph-network
mv "$scratch" ./morph-network

