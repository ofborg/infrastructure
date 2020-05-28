#!/usr/bin/env nix-shell
#!nix-shell -i bash ../shell.nix
#shellcheck shell=bash

echo "$NIX_PATH"

set -eux

fetchrepo() {
    dest=$1
    src=$2
    branch=$3
    remote=$(echo "$src" | md5sum | cut -d' ' -f1)

    if [ ! -d "$dest" ]; then
        git clone "$src" "$dest"
    fi

    (
        cd "$dest"
        if ! git remote | grep -q "$remote"; then
            git remote add "$remote" "$src"
        fi

        git fetch "$remote"
        git clean -dfx
        git checkout "$remote/$branch"
    )
}

mkdir -p repos
fetchrepo repos/ofborg https://github.com/nixos/ofborg.git released
fetchrepo repos/log-viewer https://github.com/samueldr/ofborg-viewer.git master

if [ "${1:-x}" != "--do-it-live" ]; then
    nixops deploy --dry-activate --check --allow-recreate
else
    # We want to remove unused systems, but definitely don't want to remove
    # core-0. To achieve this, we first deploy only to core-0, followed by a
    # deploy to the rest of the hosts, where obsolete hosts will be dropped.
    nixops deploy --check --allow-recreate --include core-0
    nixops deploy --check --allow-recreate --kill-obsolete --exclude core-0 --confirm
fi
