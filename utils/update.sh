#!/usr/bin/env bash

CACHE_PROXY="https://ncps.k8s.lan"

if [ "$#" -lt 1 ]; then
    echo "ERROR: Illegal number of parameters $# ($*)"
    echo "USage: nix run '.#update-system' -- \$TARGET [\$IP]"
    exit 1
fi

TARGET="$1"; shift

if [ "$(curl -o /dev/null -s -w '%{http_code}' "$CACHE_PROXY")" = "200" ]; then
    echo "use local cache server: $CACHE_PROXY"
    if ! nixos-rebuild build --option extra-substituters "$CACHE_PROXY?priority=1&trusted=1" --flake ".#${TARGET}"; then
        exit 1
    fi
    echo "upload build artifacts to local cache server..."
    nix copy --to "$CACHE_PROXY/?parallel-compression=true" "$(readlink -f ./result)"
    echo "upload completed"
fi

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
