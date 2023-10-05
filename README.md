# My NixOS Modules

My NixOS Modules hosted on my personal Git Server. Feel free to look around. Be aware that not all configuration files are available in my public repository.

## Setup

### Create Secret Key in Vault

```bash
nix run '.#vault-hostkey' -- $TARGET -g
```

### Crete SOPS secret file

```bash
nix run '.#vault-age-sops -- $TARGET $SECRET_FILE'
```

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
