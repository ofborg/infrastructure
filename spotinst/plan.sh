#!/usr/bin/env nix-shell
#!nix-shell -p curl -p jq -i bash -p bc

set -eux
set -o pipefail


. ./config.sh

function standard_price() {
    PLAN="$1"
    curl -v \
    --header 'Accept: application/json' \
         --header 'Content-Type: application/json' \
         --header "X-Auth-Token: $token" \
         'https://api.packet.net/plans' \
         |  jq "
              .plans
              | map(select(.slug == \"$PLAN\"))
              | first
              | .pricing.hour
            "
}

function spot_price() {
    REGION="$1"
    PLAN="$2"
    curl -v \
    --header 'Accept: application/json' \
         --header 'Content-Type: application/json' \
         --header "X-Auth-Token: $token" \
         'https://api.packet.net/market/spot/prices' \
         | jq ".spot_market_prices.$REGION.$PLAN.price"
}

function builds() {
    curl -v \
         'https://events.nix.ci/stats.php' \
         | jq '."build-queues"."build-inputs-x86_64-linux".messages.in_progress
               + ."build-queues"."build-inputs-x86_64-linux".messages.waiting
                    '
}

function required_builders() {
    echo "
      scale = 0;

      define max (a, b) {
        if (a > b) return (a);
        return b;
      }

      max(($1 / 5), 1" | bc -l
}




region=ewr1
plan=baremetal_0
spot=$(spot_price "$region" "$plan")
standard=$(standard_price "$plan")
desired=$(required_builders "$(builds)")

echo $desired
if echo "$standard>$spot" | bc -l; then
    echo "spot"
else
    echo "standard"
fi
