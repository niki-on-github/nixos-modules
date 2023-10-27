#!/usr/bin/env bash

NIXOS_ANYWERE_COMMIT="3686956935964ef245363586deda4197ba762632"

if [ "$#" -lt 2 ]; then
    echo "ERROR: Illegal number of parameters $# ($*)"
    echo "Usage: nix run '.#install-system' -- \$TARGET \$SSH_USER@\$IP [\$DIR_WITH_SSH_KEYS]"
    exit 1
fi

TARGET="$1"; shift
HOST="$1"; shift
VAULT_ADDR="https://vault.server01.lan"
VAULT_KEYNAME="$TARGET"
RED='\033[0;31m'
NC='\033[0m'

temp=$(mktemp -d)

cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

install -d -m755 "$temp/boot"
install -d -m755 "$temp/boot/keys"
install -d -m755 "$temp/etc"
install -d -m755 "$temp/etc/ssh"

if [ "$#" -lt 1 ]; then
    read -r -s -p 'vault token: ' vault_token
    echo "*****"
    secret_status=$(curl --write-out '%{http_code}' --silent --output /dev/null -H "X-Vault-Token: $vault_token" "$VAULT_ADDR/v1/host/$VAULT_KEYNAME")

    if [[ "$secret_status" -eq 503 ]] ; then
        echo -e "${RED}ERROR: Vault server errors please check you vault server logs${NC}"
        exit 1
    fi

    if [[ "$secret_status" -eq 403 ]] ; then
        echo -e "${RED}ERROR: Invalid vault token for ${VAULT_ADDR}${NC}"
        exit 1
    fi

    if [[ "$secret_status" -ne 200 ]] ; then
        echo -e "${RED}ERROR: host keys for '$VAULT_KEYNAME' do not exist on vault server ($secret_status)${NC}"
        echo "Import an existing secret or create a new host keypair with 'create-hostkey.sh' script"
        exit 1
    fi

    curl -s -H "X-Vault-Token: $vault_token" "$VAULT_ADDR/v1/host/$VAULT_KEYNAME" | jq  '.data | keys[] as $k | "\($k) \(.[$k] | .)"' | sed 's/"//g' | while read -r line ; do
        name=$(echo "$line" | cut -d ' ' -f 1)
        content=$(echo "$line" | cut -d ' ' -f 2-)
        echo -e "$content" | sed 's/\\n/\n/g' > "$temp/etc/ssh/$name"
        if grep -qE ".*\.pub$" <<< "$name"; then
            chmod 644 "$temp/etc/ssh/$name"
        else
            chmod 600 "$temp/etc/ssh/$name"
        fi
    done
else
    cp -afv "$1/." "$temp/etc/ssh"
fi

if [ ! -f "$temp/etc/ssh/ssh_host_ed25519_key" ]; then
    echo "ssh_host_ed25519_key do not exist in your vault key/value store for host $VAULT_KEYNAME"
    exit 1
fi

cp -fv "$temp/etc/ssh/ssh_host_ed25519_key" "$temp/boot/keys/disk.key"

echo "extra files:"
tree -p -a "$temp"

eval "nix --extra-experimental-features nix-command --extra-experimental-features flakes run "github:nix-community/nixos-anywhere/$NIXOS_ANYWERE_COMMIT" -- --extra-files \"$temp\" --disk-encryption-keys /tmp/disk.key \"$temp/boot/keys/disk.key\" --flake \".#$TARGET\" -t $HOST"
