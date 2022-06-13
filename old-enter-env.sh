#!/usr/bin/env nix-shell
#!nix-shell -i bash ./shell.nix

set +x # don't leak secrets!
set -eu

scriptroot=$(dirname "$(realpath "$0")")
scratch=$(mktemp -d -t tmp.XXXXXXXXXX)

function finish {
  git remote rm vaultpush 2>/dev/null || true
  rm -rf "$scratch"
  if [ "x${VAULT_EXIT_ACCESSOR:-}" != "x" ]; then
    echo "--> Revoking my token..." >&2
    vault token revoke -self
  fi
}
trap finish EXIT

echo "--> Assuming role: ofborg-deployers" >&2
vault_creds=$(vault token create \
	-display-name=ofborg-infrastructure \
	-format=json \
	-role ofborg-deployers)

VAULT_EXIT_ACCESSOR=$(jq -r .auth.accessor <<<"$vault_creds")
expiration_ts=$(($(date '+%s') + "$(jq -r .auth.lease_duration<<<"$vault_creds")"))
export VAULT_TOKEN=$(jq -r .auth.client_token <<<"$vault_creds")

echo "--> Setting variables: PACKET_AUTH_TOKEN" >&2
export PACKET_AUTH_TOKEN=$(vault kv get -field api_key_token packet/creds/nixos-foundation)

echo "--> Creating authenticated git remote: vaultpush" >&2
git remote rm vaultpush 2>/dev/null || true
pushtoken=$(vault write -field token github-ofborg/token repository_ids=122906544 permissions=contents=write)
git remote add vaultpush "https://x-access-token:$pushtoken@github.com/ofborg/infrastructure.git"

if [ "x${1:-}" == "x" ]; then

cat <<BASH > "$scratch/bashrc"
vault_prompt() {
  remaining=\$(( $expiration_ts - \$(date '+%s')))
  if [ \$remaining -gt 0 ]; then
    PS1='\n\[\033[01;32m\][TTL:\${remaining}s:\w]\$\[\033[0m\] ';
  else
    remaining=expired
    PS1='\n\[\033[01;33m\][\$remaining:\w]\$\[\033[0m\] ';
  fi
}
PROMPT_COMMAND=vault_prompt
BASH

bash --init-file "$scratch/bashrc"
else
  "$@"
fi
