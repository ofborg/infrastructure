#!/usr/bin/env nix-shell
#!nix-shell -i bash ../shell.nix
#shellcheck shell=bash

set -eux

"$(dirname "$0")"/build.sh --do-it-live
