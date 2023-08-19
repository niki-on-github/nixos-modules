#!/usr/bin/env bash

DEPLOY_RS_COMMIT="724463b5a94daa810abfc64a4f87faef4e00f984"

if [ "$#" -lt 2 ]; then
    echo "ERROR: Illegal number of parameters $# ($*)"
    echo "USage: nix run '.#update-system' -- \$TARGET \$IP"
    exit 1
fi

TARGET="$1"; shift
HOSTNAME="$1"; shift
nix --extra-experimental-features nix-command --extra-experimental-features flakes run "github:serokell/deploy-rs/$DEPLOY_RS_COMMIT" ".#$TARGET" -- --hostname "$HOSTNAME"
