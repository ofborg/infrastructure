#!/usr/bin/env nix-shell
#!nix-shell -i bash ../shell.nix

set -eux
exit 1
nixops deploy
