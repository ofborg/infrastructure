#!/usr/bin/env nix-shell
#!nix-shell -p curl -p jq -i bash

. ./config.sh

function fetch_instances() {
    curl \
        --header 'Accept: application/json' \
         --header 'Content-Type: application/json' \
         --header "X-Auth-Token: $token" \
         'https://api.packet.net/projects/ed99fc89-822f-4889-94f6-1fbcb803fef8/devices?per_page=100'
}

fetch_instances | jq -r '
  .devices
  | map(select(.tags != []))
  | map(select(.state == "active"))
  ' > instances.json
