#!/usr/bin/env nix-shell
#!nix-shell -i bash ../shell.nix

set -eux

git-crypt unlock

fetchrepo() {
    dest=$1
    src=$2
    branch=$3

    if [ ! -d "$dest" ]; then
        git clone "$src" "$dest"
    fi

    (
        cd "$dest"
        git fetch --update-head-ok "$src" "$branch":up/rem
        git checkout up/rem
    )
}

mkdir -p repos
fetchrepo repos/ofborg https://github.com/nixos/ofborg.git released
fetchrepo repos/log-viewer https://github.com/samueldr/ofborg-viewer.git master

# nixops deploy
