#!/usr/bin/env nix-shell
#!nix-shell -i bash ../shell.nix

set -eux

nixops deploy
