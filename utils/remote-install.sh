#!/usr/bin/env bash

NIXOS_ANYWERE_COMMIT="5cdd6d6d2633498ff65dd6b15eaec8b9b8e7a3e2"

if [ "$#" -lt 2 ]; then
    echo "ERROR: Illegal number of parameters $# ($*)"
    echo "Usage: nix run '.#install-system' -- \$TARGET \$SSH_USER@\$IP"
    exit 1
fi

if ! command -v ssh-to-pgp >/dev/null ; then
    echo -e "${RED}ERROR: 'ssh-to-pgp' is not available (do you use the correct environment?)${NC}"
    exit 1
fi

TARGET="$1"; shift
VAULT_ADDR="https://vault.server01.lan"
VAULT_KEYNAME="$TARGET"
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'

temp=$(mktemp -d)

cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

install -d -m755 "$temp/boot"
install -d -m755 "$temp/boot/keys"

dd bs=512 count=8 if=/dev/random of="$temp/boot/keys/disk.key" iflag=fullblock

read -r -s -p 'vault token: ' vault_token
echo "*****"
secret_status=$(curl --write-out '%{http_code}' --silent --output /dev/null -H "X-Vault-Token: $vault_token" "$VAULT_ADDR/v1/sops/export/encryption-key/$VAULT_KEYNAME")

if [[ "$secret_status" -eq 503 ]] ; then
    echo -e "${RED}ERROR: Vault server errors please check you vault server logs${NC}"
    exit 1
fi

if [[ "$secret_status" -eq 403 ]] ; then
    echo -e "${RED}ERROR: Invalid vault token for ${VAULT_ADDR}${NC}"
    exit 1
fi

if [[ "$secret_status" -ne 200 ]] ; then
    echo -e "${RED}ERROR: SOPS secret '$VAULT_KEYNAME' do not exist on vault server ($secret_status)${NC}"
    echo "Import an existing secret with:"
    echo " ~$ VAULT_ADDR=\"$VAULT_ADDR\" VAULT_TOKEN=\$TOKEN vault transit import sops/keys/$VAULT_KEYNAME \"\$(openssl rsa -in exported.key -outform DER | openssl base64)\" type=rsa-4096 exportable=true"
    echo "or create a new secret with:"
    echo " ~$ VAULT_ADDR=\"$VAULT_ADDR\" VAULT_TOKEN=\$TOKEN vault write sops/keys/$VAULT_KEYNAME exportable=true type=rsa-4096"
    exit 1
fi

curl -s -H "X-Vault-Token: $vault_token" "$VAULT_ADDR/v1/sops/export/encryption-key/$VAULT_KEYNAME" | jq -r '.data.keys."1"' > "$temp/boot/keys/sops.key"
pgp_fingerprint=$(ssh-to-pgp -i "$temp/boot/keys/sops.key" -private-key -o "$temp/boot/keys/sops.asc" 2>&1)
gpg --import "$temp/boot/keys/sops.asc"

echo "check sops secrets:"
find . -iname "*.sops.yaml" -print0 | while read -r -d $'\0' f; do
    echo -n " - $f: "
    if grep -q "vault_address: $VAULT_ADDR" "$f"; then
        if ! grep -q "fp: $pgp_fingerprint" "$f"; then
            echo "insert pgp fingerprint \"$pgp_fingerprint\" (please commit this changes)"
            VAULT_TOKEN=$vault_token sops -r -i --add-pgp "$pgp_fingerprint" "$f"
        else
            echo "gpg fingerprint is available"
        fi
    else
        echo -e "${ORANGE}do not use an vault secret${NC}"
    fi
done

eval "nix --extra-experimental-features nix-command --extra-experimental-features flakes run "github:numtide/nixos-anywhere/$NIXOS_ANYWERE_COMMIT" -- --extra-files \"$temp\" --flake \".#$TARGET\" -t $*"
