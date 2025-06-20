#!/usr/bin/env bash
# Description: Script to generate vault hostkeys

if [ "$#" -lt 2 ]; then
    echo "ERROR: Illegal number of parameters $# ($*)"
    echo "Usage: nix run '.#vault-hostkey' -- \$TARGET [-g/-e/-s/-a] \$ARGS"
    echo "Examples:"
    echo " - nix run '.#vault-hostkey' -- \$TARGET -g"
    echo " - nix run '.#vault-hostkey' -- \$TARGET -e"
    echo " - nix run '.#vault-hostkey' -- \$TARGET -s nix@\$IP"
    echo " - nix run '.#vault-hostkey' -- \$TARGET -a USERNAME@SERVER [-p 23]"
    exit 1
fi

TARGET="$1"; shift
OPTION="$1"; shift
VAULT_ADDR="https://vault.k8s.lan"

read -r -s -p 'vault token: ' vault_token
echo "*****"

VAULT_TOKEN=$vault_token VAULT_ADDR=$VAULT_ADDR vault secrets enable -path=host kv 2>/dev/null || true

temp=$(mktemp -d)

cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

if [ "$OPTION" = "-g" ]; then
    echo "generate hostkeys..."
    ssh-keygen -q -N "" -C "$TARGET" -t rsa -b 4096 -f "$temp/ssh_host_rsa_key"
    ssh-keygen -q -N "" -C "$TARGET" -t ed25519 -f "$temp/ssh_host_ed25519_key"
    ls "$temp"
    VAULT_TOKEN=$vault_token VAULT_ADDR=$VAULT_ADDR vault kv put \
        -mount=host \
        "$TARGET" \
        ssh_host_rsa_key="$(cat "$temp/ssh_host_rsa_key")" \
        ssh_host_rsa_key.pub="$(cat "$temp/ssh_host_rsa_key.pub")" \
        ssh_host_ed25519_key="$(cat "$temp/ssh_host_ed25519_key")" \
        ssh_host_ed25519_key.pub="$(cat "$temp/ssh_host_ed25519_key.pub")"
elif [ "$OPTION" = "-e" ]; then
    echo "export existing hostkey..."
    mkdir -p "$TARGET"
    VAULT_TOKEN=$vault_token VAULT_ADDR=$VAULT_ADDR vault kv get \
        -mount=host \
        -format=json \
        "$TARGET" \
        | jq  '.data | keys[] as $k | "\($k) \(.[$k] | .)"' | sed 's/"//g' | while read -r line ; do
        name=$(echo "$line" | cut -d ' ' -f 1)
        content=$(echo "$line" | cut -d ' ' -f 2-)
        echo -e "$content" | sed 's/\\n/\n/g' > "$TARGET/$name"
    done
    tree -p -a "$TARGET"
elif [ "$OPTION" = "-s" ]; then
    echo "setup target hostkey on \"$1\" ..."
    mkdir -p "$temp/etc/ssh"
    curl -s -H "X-Vault-Token: $vault_token" "$VAULT_ADDR/v1/host/$TARGET" | jq  '.data | keys[] as $k | "\($k) \(.[$k] | .)"' | sed 's/"//g' | while read -r line ; do
        name=$(echo "$line" | cut -d ' ' -f 1)
        content=$(echo "$line" | cut -d ' ' -f 2-)
        echo -e "$content" | sed 's/\\n/\n/g' > "$temp/etc/ssh/$name"
        if grep -qE ".*\.pub$" <<< "$name"; then
            chmod 644 "$temp/etc/ssh/$name"
        else
            chmod 600 "$temp/etc/ssh/$name"
        fi
    done
    tree -p -a "$temp"
    eval "scp -r $temp $1:/tmp"
    # shellcheck disable=SC2029
    ssh -t "$1" eval "sudo mv -f $temp/etc/ssh/* /etc/ssh"
elif [ "$OPTION" = "-a" ]; then
    echo "add hostkey to authorized_keys on \"$1\" ..."
    mkdir -p "$temp/etc/ssh"
    curl -s -H "X-Vault-Token: $vault_token" "$VAULT_ADDR/v1/host/$TARGET" | jq  '.data | keys[] as $k | "\($k) \(.[$k] | .)"' | sed 's/"//g' | while read -r line ; do
        name=$(echo "$line" | cut -d ' ' -f 1)
        content=$(echo "$line" | cut -d ' ' -f 2-)
        echo -e "$content" | sed 's/\\n/\n/g' > "$temp/etc/ssh/$name"
        if grep -qE ".*\.pub$" <<< "$name"; then
            chmod 644 "$temp/etc/ssh/$name"
        else
            chmod 600 "$temp/etc/ssh/$name"
        fi
    done
    tree -p -a "$temp"
    DEST="$1"
    shift
    for pubkey in "$temp"/etc/ssh/*.pub; do
        cmd="ssh-copy-id -i \"$pubkey\" \"$*\" -s $DEST"
        echo "$cmd"
        eval "$cmd"
    done
else
    echo "invalid arg $OPTION"
    exit 1
fi

