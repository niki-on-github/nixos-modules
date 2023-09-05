#!/usr/bin/env bash

if [ "$#" -lt 1 ]; then
    echo "ERROR: Illegal number of parameters $# ($*)"
    echo "Usage: nix run '.#todo' -- \$TARGET"
    exit 1
fi

TARGET="$1"; shift
VAULT_ADDR="https://vault.server01.lan"

temp=$(mktemp -d)

cleanup() {
  rm -rf "$temp"
}

ssh-keygen -q -N "" -C "$TARGET" -t rsa -b 4096 -f "$temp/ssh_host_rsa_key"
ssh-keygen -q -N "" -C "$TARGET" -t ed25519 -f "$temp/ssh_host_ed25519_key"

ls "$temp"

read -r -s -p 'vault token: ' vault_token
echo "*****"

VAULT_TOKEN=$vault_token VAULT_ADDR=$VAULT_ADDR vault secrets enable -path=host kv 2>/dev/null

VAULT_TOKEN=$vault_token VAULT_ADDR=$VAULT_ADDR vault kv put \
    -mount=host \
    $TARGET \
    ssh_host_rsa_key="$(cat "$temp/ssh_host_rsa_key")" \
    ssh_host_rsa_key.pub="$(cat "$temp/ssh_host_rsa_key.pub")" \
    ssh_host_ed25519_key="$(cat "$temp/ssh_host_ed25519_key")" \
    ssh_host_ed25519_key.pub="$(cat "$temp/ssh_host_ed25519_key.pub")"

VAULT_TOKEN=$vault_token VAULT_ADDR=$VAULT_ADDR vault kv get \
    -mount=host \
    -format=json \
    $TARGET \
    | jq '.data'
