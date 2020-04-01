#!/usr/bin/env nix-shell
#!nix-shell -i bash ../shell.nix -I nixpkgs=channel:nixpkgs-unstable

set -eux

nixops deploy
