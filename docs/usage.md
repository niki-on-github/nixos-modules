# Usage

## Flake

Example flake config:

```nix
{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-23.05";
    };

    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
    };


    deploy-rs = {
      url = "github:serokell/deploy-rs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
    };

    nur = {
      url = "github:nix-community/NUR";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    personalModules = {
      url = "git+https://git.server01.lan/r/nixos-modules.git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
      inputs.nur.follows = "nur";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, deploy-rs, home-manager, sops-nix, agenix, nur, disko, personalModules, ... } @ inputs:
    let
      inherit (nixpkgs) lib;
      overlays = lib.flatten [
        nur.overlay
        personalModules.overrides
        personalModules.pkgs
      ];
      nixosDeployments = personalModules.utils.deploy.generateNixosDeployments {
        inherit inputs;
        path = ./systems;
        ssh-user = "nix";
        sharedModules = [
          { nixpkgs.overlays = overlays; }
          sops-nix.nixosModules.sops
          agenix.nixosModules.default
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
        ];
      };
    in
    {
      inherit (personalModules) formatter devShells packages nixosModules homeManagerModules nixosRoles homeManagerRoles;
      inherit (nixosDeployments) nixosConfigurations deploy checks;
    };
}
```

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

When installing from arch linux you need to first run `mount -o remount,size=2G /run/archiso/cowspace` to have enough space.

#### Update

```bash
sudo nixos-rebuild switch --flake ".#$TARGET" --upgrade

```

For complexer systems i recommend to switch after boot via:

```sh
sudo nixos-rebuild boot --flake ".#$TARGET" --upgrade
```

