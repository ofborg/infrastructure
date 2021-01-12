#!/usr/bin/env nix-shell
#!nix-shell ../terraform/shell.nix -i bash
# shellcheck shell=bash
set -eux

tfconfig=$1
applypipeline=$2
nextpipeline=$2

scriptroot=$(dirname "$(realpath "$0")")

cd "$scriptroot/../terraform/$tfconfig/"

set +e
terraform init
terraform plan -detailed-exitcode -input=false -out ./terraform.plan
exitcode=$?
set -e

if [ "$exitcode" -eq 2 ]; then
  echo "Diff present, uploading pipeline apply stage."
  buildkite-agent pipeline upload "$applypipeline"
elif [ "$exitcode" -eq 0 ]; then
  echo "No change, uploading the next stage."
  buildkite-agent pipeline upload "$nextpipeline"
else
  exit "$exitcode"
fi
