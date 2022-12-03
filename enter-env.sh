#!/usr/bin/env nix-shell
#!nix-shell ./shell.nix -i bash
# shellcheck shell=bash

set +x # don't leak secrets!
set -eu
umask 077

export VAULT_ADDR="https://vault.detsys.dev:8200"
scriptroot=$(dirname "$(realpath "$0")")
scratch=$(mktemp -d -t tmp.XXXXXXXXXX)

function finish {
  set +e
  rm -rf "$scratch"
  if [ "${VAULT_EXIT_ACCESSOR:-}" != "" ]; then
    echo "--> Revoking my token..." >&2
    vault token revoke -self
    echo "--> Removing secret files..." >&2
    rm -rf \
      "$scriptroot/terraform/rabbitmq/vars.auto.tfvars.json" \
      "$scriptroot/private/local.nix" \
      "$scriptroot/private/github.key" \
      "$scriptroot/private/github.key.pem" \
      "$scriptroot/deploy.key" \
      "$scriptroot/deploy.key.pub" \
      "$scriptroot/deploy.key-cert.pub"
  fi
  set -e
}
trap finish EXIT

if [ "${BUILDKITE:-}" = "true" ]; then
    vault login -no-print -method=aws role=buildkite_ofborg
fi

assume_role() {
    role=$1
    echo "--> Assuming role: $role" >&2
    vault_creds=$(vault token create \
        -display-name="$role" \
        -format=json \
        -role "$role")

    VAULT_EXIT_ACCESSOR=$(jq -r .auth.accessor <<<"$vault_creds")
    expiration_ts=$(($(date '+%s') + "$(jq -r .auth.lease_duration<<<"$vault_creds")"))
    export VAULT_TOKEN
    VAULT_TOKEN=$(jq -r .auth.client_token <<<"$vault_creds")
}

function provision_aws_creds() {
    url="$1"
    local ok=
    echo "--> Setting AWS variables: " >&2
    echo "                       AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN" >&2

    aws_creds=$(vault kv get -format=json "$url")
    export AWS_ACCESS_KEY_ID
    AWS_ACCESS_KEY_ID=$(jq -r .data.access_key <<<"$aws_creds")
    export AWS_SECRET_ACCESS_KEY
    AWS_SECRET_ACCESS_KEY=$(jq -r .data.secret_key <<<"$aws_creds")
    export AWS_SESSION_TOKEN
    AWS_SESSION_TOKEN=$(jq -r .data.security_token <<<"$aws_creds")
    if [ -z "$AWS_SESSION_TOKEN" ] ||  [ "$AWS_SESSION_TOKEN" == "null" ]; then
        unset AWS_SESSION_TOKEN
    fi

    unset aws_creds

    echo "--> Preflight testing the AWS credentials..." >&2
    for _ in {0..20}; do
        if check_output=$(aws sts get-caller-identity 2>&1 >/dev/null); then
            ok=1
            break
        else
            echo -n "." >&2
            sleep 1
        fi
    done
    if [[ -z "$ok" ]]; then
        echo $'\nPreflight test failed:\n'"$check_output" >&2
        return 1
    fi
    echo
}

function provision_ssh_key() {
    url="$1"
    echo "--> Signing SSH key deploy.key.pub -> deploy.key-cert.pub" >&2

    if [ ! -f "$scratch/deploy.key" ]; then
        ssh-keygen -t rsa -f "$scratch/deploy.key" -N ""
    fi

    vault write -field=signed_key \
        "$url" public_key=@"$scratch/deploy.key.pub" > "$scratch/deploy.key-cert.pub"
    export SSH_IDENTITY_FILE="$scratch/deploy.key"
    export SSH_USER=root
    export SSH_CONFIG_FILE="$scratch/ssh-config"
    export NIX_SSHOPTS="-F $SSH_CONFIG_FILE"
    cat <<EOF > "$SSH_CONFIG_FILE"
StrictHostKeyChecking no
UserKnownHostsFile $scriptroot/morph-network/known_hosts
BatchMode yes
IdentitiesOnly yes
IdentityFile $SSH_IDENTITY_FILE
EOF

    echo "--> Created SSH config file at $SSH_CONFIG_FILE" >&2
    cat "$SSH_CONFIG_FILE" >&2
}

assume_role "ofborg_ofborg_developer"
provision_ssh_key "ofborg/ofborg/ssh_keys/sign/root"
provision_aws_creds "internalservices/aws/creds/ofborg_ofborg_DeployState"

echo "--> Setting variables: PACKET_AUTH_TOKEN, CLOUDAMQP_APIKEY" >&2
export PACKET_AUTH_TOKEN=$(vault kv get -field api_key_token ofborg/ofborg/packet/creds/nixos_foundation)
export CLOUDAMQP_APIKEY=$(vault kv get -field key ofborg/ofborg/kv/cloudamqp.key)
vault kv get -field=data ofborg/ofborg/kv/rabbitmq.vars.json > "$scriptroot/terraform/rabbitmq/vars.auto.tfvars.json"
vault kv get -field=expression ofborg/ofborg/kv/local.nix > "$scriptroot/private/local.nix"
vault kv get -field=key ofborg/ofborg/kv/github.key > "$scriptroot/private/github.key.pem"
# hubcaps expects the DER bytes of the key, not the PEM bytes
openssl rsa -in "$scriptroot/private/github.key.pem" -outform DER -out "$scriptroot/private/github.key"

if [ "${1:-}" == "" ]; then
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
