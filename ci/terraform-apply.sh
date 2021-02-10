#!/usr/bin/env nix-shell
#!nix-shell ../shell.nix -i bash
# shellcheck shell=bash

set -eux

tfconfig=$1
nextpipeline=$2

scriptroot=$(dirname "$(realpath "$0")")

buildkite-agent artifact download "terraform/$tfconfig/terraform.plan" .

cd "$scriptroot/../terraform/$tfconfig/"

terraform init
terraform apply -input=false ./terraform.plan

buildkite-agent pipeline upload "$scriptroot/../$nextpipeline"
