#!/usr/bin/env nix-shell
#!nix-shell ./shell.nix -i bash
# shellcheck shell=bash

set +x # don't leak secrets!
set -eu
umask 077

scriptroot=$(dirname "$(realpath "$0")")
scratch=$(mktemp -d -t tmp.XXXXXXXXXX)

function finish {
  set +e
  rm -rf "$scratch"
  echo "--> Removing secret files..." >&2
  rm -rf \
    "$scriptroot/terraform/rabbitmq/vars.auto.tfvars.json"
  set -e
}
trap finish EXIT

# TODO: make agenix-cli support reading passphrase and id file from env, so we can not need to enter passphrase every time
# FIXME: agenix-cli should check only the path of the subdir, not the entire path
# FIXME: agenix-cli should put the "real filename" at the end, so that extensions work as expected
echo "--> Setting variable: CLOUDAMQP_APIKEY" >&2
export CLOUDAMQP_APIKEY="$(EDITOR=cat agenix "secrets/admins/cloudamqp.key")"
echo "--> Decrypting rabbitmq vars for terraform..." >&2
EDITOR=cat agenix "secrets/admins/rabbitmq-tfvars.json" > "$scriptroot/terraform/rabbitmq/vars.auto.tfvars.json"

if [ "${1:-}" == "" ]; then
  bash
else
  "$@"
fi
