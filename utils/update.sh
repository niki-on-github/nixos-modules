#!/usr/bin/env bash

DEPLOY_RS_COMMIT="31c32fb2959103a796e07bbe47e0a5e287c343a8"

if [ "$#" -lt 1 ]; then
    echo "ERROR: Illegal number of parameters $# ($*)"
    echo "USage: nix run '.#update-system' -- \$TARGET [\$IP]"
    exit 1
fi

TARGET="$1"; shift

if [ "$#" -lt 1 ]; then
    read -r -p 'Update local system, confirm with yes (y/N): ' choice
    case "$choice" in
        y|Y|yes|Yes) exec sudo nixos-rebuild switch --flake ".#$TARGET" --upgrade;;
        *) exit 0;;
    esac
fi

HOSTNAME="$1"; shift

if [ -n "$HOSTNAME" ]; then
    nix --extra-experimental-features nix-command --extra-experimental-features flakes run "github:serokell/deploy-rs/$DEPLOY_RS_COMMIT" ".#$TARGET" -- --hostname "$HOSTNAME"
fi