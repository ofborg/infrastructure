#!/usr/bin/env nix-shell
#!nix-shell -p curl -p jq -i bash

set -eux

. ./config.sh

function make_spot() {
    HOSTNAME="$1"
    PLAN="$2"
    TYPE="$3"
    PRICE="$4"
    curl -v --data '{
	"facility": "any",
	"plan": "'"$PLAN"'",
	"hostname": "'"$HOSTNAME"'",
	"description": "Spot instance for '"$TYPE"'",
	"billing_cycle": "hourly",
	"operating_system": "nixos_18_03",
	"userdata": "",
	"locked": "false",
	"spot_instance": true,
	"spot_price_max": '"$PRICE"',
	"tags": [
          "'"$TYPE"'"
	],
	"project_ssh_keys": [
	],
	"user_ssh_keys": [
	],
	"features": [
	]
        }
    ' --header 'Accept: application/json' \
         --header 'Content-Type: application/json' \
         --header "X-Auth-Token: $token" \
         'https://api.packet.net/projects/ed99fc89-822f-4889-94f6-1fbcb803fef8/devices' \
         | jq .href
}

# want to make not-spot builders? use terraform!
make_spot spot-evaluator-3 x1.small.x86 evaluator 0.10
