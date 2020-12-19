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

machines | while read machine; do
	name="$(jq -r .key <<<"$machine")"
	ip=$(jq -r .value.ip <<<"$machine")
	jq -r .value.expression <<<"$machine" > "$scratch/machines/${name}.expr.nix"
  	ssh "root@$ip" -- cat /etc/nixos/packet/system.nix > "$scratch/machines/${name}.system.nix"

        printf "  %s = { deployment.targetHost = "%s"; import = [ ./machines/%s.expr.nix ./machines/%s.system.nix ]; };\n" "$name" "$ip" "$name" "$name" >> "$scratch/default.nix"
done

rm -rf ./target
mv "$scratch" ./target

