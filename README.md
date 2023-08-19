# My NixOS Modules

My NixOS Modules hosted on my personal Git Server. Feel free to look around. Be aware that not all configuration files are available in my public repository.

## Deployment

### Clone Repository

```bash
git -c http.sslVerify=false clone $URL
```

### Remote

#### Install

```bash
nix run '.#install-system' -- $TARGET nixos@$IP
```

#### Update

```bash
nix run '.#update-system' -- $TARGET $IP
```

### Local

#### Install

```bash
nix-env -iA nixos.pkgs.git
sudo nix --extra-experimental-features nix-command --extra-experimental-features flakes run github:nix-community/disko -- --mode disko ./system-disk.nix --arg device "/dev/disk/by-id/$NAME"
sudo nixos-install --root /mnt --flake '.#$TARGET'
```

#### Update

```bash
sudo nixos-rebuild switch --flake ".#$TARGET" --upgrade
```

## Update

```bash
nix flake update
```

## Secret Management with SOPS + Vault

We provide the option `nix run '.#create-secret' -- $SECRET_FILENAME $VAULT_KEYNAME` to create a new sops secret file. Below are more details for the secret setup.

All `vault-cli` commands need the following environment variables:

- `VAULT_TOKEN`: Access token for vault. You can create an new one with your admin token and `vault token create -id $NEW_TOKEN`.
- `VAULT_ADDR`: Vault server address

Problems:

- Vault do not support Age keys [#12786](https://github.com/hashicorp/vault/issues/12786) so we have to use PGP Keys for the Encryption.
- Vault only store a `rsa-4096` key.
- `sops-nix` need the encryption key at boot time so we have to add the PGP decryption key fingerprint to each SOPS secret file.

The idea is to use the vault `rsa-4096` key stored on the nixos encrypted system disk in `/boot/keys/sops.key`. Therefor we have to perform the following steps

1. Export the `rsa-4096` key from vault
2. Convert the exported `rsa-4096` with `ssh-to-pgp` to an SOPS compatible PGP key.
3. Add PGP key fingerprint to each SOPS secret file.
4. Add `sops.gnupg.sshKeyPaths = [ "/boot/keys/sops.key" ];` and `sops.age.sshKeyPaths = [ ];` to your system flake file.
5. Store the exported `rsa-4096` key in `/boot/keys/sops.key`.

Below are the required commands to add the fingerprint of the PGP converted `rsa-4096` key from vault to the sops secret file:

```bash
export VAULT_TOKEN=$TOKEN
sops -r -i --add-pgp $FINGERPRINT secret.yaml
nix-shell -p 'import (fetchTarball "https://github.com/Mic92/ssh-to-pgp/archive/main.tar.gz") {}'
curl -s -H "X-Vault-Token: $TOKEN" https://vault.server01.lan/v1/sops/export/encryption-key/supermicro-k3s | jq -r '.data.keys."1"' | ssh-to-pgp | gpg --import
VAULT_TOKEN=$TOKEN sops -r -i --add-pgp "$GPG_FINGERPINT_SHA" secrets.yaml
```

NOTE: If sops failed to fetch the unlock secret from vault when adding the new PGP fingerprint we will get an empty sops file! In this case you have to restore your sops file from git and perform the commands above again.

The workaround described above is automatically performed when you use the `./utils/remote-install.sh` script (`nix run '.#install-system' -- $TARGET_NAME nixos@$IP`).

### Setup

On your vault server you have to setup the sops transit once with:

```bash
vault secrets enable -path=sops transit
```

### Create new SOPS Key in Vault

```bash
vault write sops/keys/$KEYNMAE exportable=true type=rsa-4096
```

### Import existing `rsa-4096` SOPS Key to Vault

```bash
vault transit import sops/keys/$KEYNMAE "$(openssl rsa -in exported.key -outform DER | openssl base64)" type=rsa-4096 exportable=true
```

### Export/Show SOPS Key from Vault

With `valut-cli`:

```bash
vault read sops/export/encryption-key/$KEYNMAE
```

With REST API:

```bash
curl -s -H "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/sops/export/encryption-key/$KEYNAME | jq -r '.data.keys."1"' > exported.key
```

### Create new SOPS Encrypted secret with Key stored in Vault

```bash
export VAULT_TOKEN=$TOKEN
sops --hc-vault-transit $VAULT_ADDR/v1/sops/keys/$KEYNMAE secrets.yaml
```
