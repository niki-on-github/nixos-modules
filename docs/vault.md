# Notes

## Vault


### Setup
1. generate policy `remoteunlock-$TARGETNAME` by using use webui `https://vault.k8s.lan/ui/vault/policies/acl`.

```
path "host/$TARGETNAME" {
  capabilities = ["read"]
}
```

replace `$TARGETNAME` with target name.

2. generate token with policy:

```sh
export NIXPKGS_ALLOW_UNFREE=1
nix-shell -p vault-bin
export VAULT_ADDR="https://vault.k8s.lan"
vault login $VAULTTOKEN
vault token create -ttl=99999d -policy=remoteunlock-$TARGETNAME -metadata="name=$TARGETNAME"
```

Dont forget to copy the actual token

### list tokens

```sh
vault list -format json auth/token/accessors | jq -r .[] | xargs -I '{}' vault token lookup -format json -accessor '{}'
```
