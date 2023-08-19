#!/usr/bin/env bash

if [ "$#" -lt 2 ]; then
    echo "ERROR: Illegal number of parameters $# ($*)"
    echo "Usage: nix run '.#create-secret' -- \$FILENAME \$VAULT_KEYNAME"
    exit 1
fi

RED='\033[0;31m'
NC='\033[0m'
VAULT_ADDR="https://vault.server01.lan"
DESTINATION="$1"; shift
VAULT_KEYNAME="$1"; shift

if ! grep -q ".sops.yaml" <<< "$DESTINATION"; then
    echo -e "${RED}ERROR: Secret has invalid filename. Filename must postfixed with *.sops.yaml${NC}"
    exit 1
fi

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

VAULT_TOKEN="$vault_token" sops --hc-vault-transit "$VAULT_ADDR/v1/sops/keys/$VAULT_KEYNAME" "$DESTINATION"
