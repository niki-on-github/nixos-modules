#!/usr/bin/env bash

if [ "$#" -lt 1 ]; then
    echo "ERROR: Illegal number of parameters $# ($*)"
    echo "USage: nix run '.#update-system' -- \$TARGET [\$IP]"
    exit 1
fi

TARGET="$1"; shift

function local_system_update() {
    read -r -p 'switch directly to the new system (y/N): ' choice
    case "$choice" in
        y|Y|yes|Yes) exec sudo nixos-rebuild switch --flake ".#$TARGET" --upgrade --fallback;;
        *) exec sudo nixos-rebuild boot --flake ".#$TARGET" --upgrade --fallback;;
    esac
}

if [ "$#" -lt 1 ]; then
    read -r -p 'Update local system, confirm with yes (y/N): ' choice
    case "$choice" in
        y|Y|yes|Yes) local_system_update;;
        *) exit 0;;
    esac
fi

HOSTNAME="$1"; shift

if [ -n "$HOSTNAME" ]; then
    read -r -p 'switch directly to the new system (y/N): ' choice
    case "$choice" in
        y|Y|yes|Yes) exec deploy --hostname "$HOSTNAME" -- ".#$TARGET";;
        *) exec deploy --boot --hostname "$HOSTNAME" -- ".#$TARGET";;
    esac
fi
