#!/usr/bin/env bash

if [ "$#" -lt 3 ]; then
    echo "ERROR: Illegal number of parameters $# ($*)"
    echo "Usage: nix run '.#vault-age' -- \$TARGET [-d/-e] \$FILE"
    exit 1
fi

TARGET="$1"; shift
OPTION="$1"; shift
SECRET_FILE=$1; shift
VAULT_ADDR="https://vault.server01.lan"

temp=$(mktemp -d)

cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

read -r -s -p 'vault token: ' vault_token
echo "*****"

curl -s -H "X-Vault-Token: $vault_token" "$VAULT_ADDR/v1/host/$TARGET" \
    | jq  '.data."ssh_host_ed25519_key.pub"' \
    | sed 's/"//g' \
    | sed 's/\\n/\n/g' \
    > "$temp/ssh_host_ed25519_key.pub"

curl -s -H "X-Vault-Token: $vault_token" "$VAULT_ADDR/v1/host/$TARGET" \
    | jq  '.data."ssh_host_ed25519_key"' \
    | sed 's/"//g' \
    | sed 's/\\n/\n/g' \
    > "$temp/ssh_host_ed25519_key"

if [ "$OPTION" = "-e" ]; then
    age -e -R "$temp/ssh_host_ed25519_key.pub" -o "$temp/secret" "$SECRET_FILE"
    mv -f "$temp/secret" "$SECRET_FILE"
    echo "OK"
elif [ "$OPTION" = "-d" ]; then
    age -d -i "$temp/ssh_host_ed25519_key" -o "$temp/secret" "$SECRET_FILE"
    mv -f "$temp/secret" "$SECRET_FILE"
    echo "OK"
else
    echo "invalid arg $OPTION"
    exit 1
fi
