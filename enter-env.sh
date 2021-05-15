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
    echo "--> Removing secret files..." >&2
    rm -f \
      "$scriptroot/terraform/rabbitmq/vars.auto.tfvars.json" \
      "$scriptroot/private/local.nix" \
      "$scriptroot/private/github.key" \
      "$scriptroot/deploy.key" \
      "$scriptroot/deploy.key.pub" \
      "$scriptroot/deploy.key-cert.pub" \
      "$scriptroot/ssh-config.inc"
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

echo "--> Setting variables: PACKET_AUTH_TOKEN, CLOUDAMQP_APIKEY, AWS_ACCESS_KEY_ID" >&2
echo "                       AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN" >&2
export PACKET_AUTH_TOKEN=$(vault kv get -field api_key_token packet/creds/nixos-foundation)
export CLOUDAMQP_APIKEY=$(vault kv get -field key secret/ofborg/cloudamqp.key)

aws_creds=$(vault kv get -format=json aws-personal/creds/state-ofborg)
export AWS_ACCESS_KEY_ID=$(jq -r .data.access_key <<<"$aws_creds")
export AWS_SECRET_ACCESS_KEY=$(jq -r .data.secret_key <<<"$aws_creds")
export AWS_SESSION_TOKEN=$(jq -r .data.security_token <<<"$aws_creds")
if [ -z "$AWS_SESSION_TOKEN" ] ||  [ "$AWS_SESSION_TOKEN" == "null" ]; then
  unset AWS_SESSION_TOKEN
fi

echo "--> Preflight testing the AWS credentials..." >&2
for  i in $(seq 1 100); do
  if aws sts get-caller-identity > /dev/null; then
    break;
  else
    echo "    Trying again in 1s..." >&2
    sleep 1
  fi
done

unset aws_creds

vault kv get -format=json -field data secret/ofborg/rabbitmq.vars.json > "$scriptroot/terraform/rabbitmq/vars.auto.tfvars.json"
vault kv get -field=expression secret/ofborg/local.nix > "$scriptroot/private/local.nix"
vault kv get -field=key secret/ofborg/github.key > "$scriptroot/private/github.key"

echo "--> Signing SSH key deploy.key.pub -> deploy.key-cert.pub" >&2
if [ ! -f "$scriptroot/deploy.key" ]; then
  ssh-keygen -t rsa -f "$scriptroot/deploy.key" -N ""
fi

vault write -field=signed_key \
  ssh-keys-ofborg/sign/root public_key=@"$scriptroot/deploy.key.pub" > "$scriptroot/deploy.key-cert.pub"
export SSH_IDENTITY_FILE="$scriptroot/deploy.key"
export SSH_USER=root
export SSH_CONFIG_FILE="$scriptroot/ssh-config"
export NIX_SSHOPTS="-F $SSH_CONFIG_FILE"
cat <<EOF > $SSH_CONFIG_FILE
StrictHostKeyChecking no
UserKnownHostsFile $scriptroot/morph-network/known_hosts
BatchMode yes
IdentitiesOnly yes
IdentityFile $SSH_IDENTITY_FILE
Include $SSH_CONFIG_FILE.inc
EOF

nix-instantiate --eval --json -E "let net = import $scriptroot/morph-network; in
builtins.concatStringsSep \"\n\"
  (map
    (p: ''
      Host \${p} eval-\${builtins.substring 17 10 p}
          HostName \${net.\${p}.deployment.targetHost}
          User \${net.\${p}.deployment.targetUser}
    '')
    (builtins.attrNames (builtins.removeAttrs net [ \"network\" \"core\" ])))
  +
''

  Host core
      HostName \${net.\"core\".deployment.targetHost}
      User \${net.\"core\".deployment.targetUser}
''" | jq -r > $SSH_CONFIG_FILE.inc

echo "--> Created SSH config file at $SSH_CONFIG_FILE" >&2
cat "$SSH_CONFIG_FILE" >&2


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
