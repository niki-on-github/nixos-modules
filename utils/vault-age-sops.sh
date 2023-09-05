#!/usr/bin/env bash

if [ "$#" -lt 1 ]; then
    echo "ERROR: Illegal number of parameters $# ($*)"
    echo "Usage: nix run '.#vault-age-sops' -- \$TARGET"
    exit 1
fi

TARGET="$1"; shift
VAULT_ADDR="https://vault.server01.lan"

temp=$(mktemp -d)

cleanup() {
  rm -rf "$temp"
}

read -r -s -p 'vault token: ' vault_token
echo "*****"

public_key=$(curl -s -H "X-Vault-Token: $vault_token" "$VAULT_ADDR/v1/host/$TARGET" \
    | jq  '.data."ssh_host_ed25519_key.pub"' \
    | sed 's/"//g' \
    | sed 's/\\n/\n/g')

private_key=$(curl -s -H "X-Vault-Token: $vault_token" "$VAULT_ADDR/v1/host/$TARGET" \
    | jq  '.data."ssh_host_ed25519_key"' \
    | sed 's/"//g' \
    | sed 's/\\n/\n/g')

age_recipient=$(echo "$public_key" | ssh-to-age | tr -d '\n')

echo "# created: $(date +"%Y-%m-%dT%H:%M:%S%:z")" > "$temp/age-key.txt"
echo "# public key: ${age_recipient}" >> "$temp/age-key.txt"
echo "$private_key" | ssh-to-age -private-key >> "$temp/age-key.txt"

SOPS_AGE_KEY_FILE="$temp/age-key.txt" SOPS_AGE_RECIPIENTS="${age_recipient}" sops "$@"
