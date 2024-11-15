{
  description = "My NixOS modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    nur.url = "github:nix-community/NUR";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nur, ... } @ inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };

      filterFileType = type: file:
        (lib.filterAttrs (name: type': type == type') file);

      filterExtension = extension: file:
        (lib.filterAttrs (name: value: (lib.hasSuffix extension name)) file);

      filterRegularFiles = filterFileType "regular";
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

      overrides = (lib.mapAttrsToList
        (src: _: import (./overlays + "/${src}/default.nix"))
        (builtins.readDir ./overlays)
      );

      pkgs = (final: prev: (lib.mapAttrs
        (src: _: pkgs.callPackage (./pkgs + "/${src}/default.nix") { })
        (builtins.readDir ./pkgs))
      );

      utils = {
        deploy = import ./lib/deploy { inherit lib; };
      };

      devShells.x86_64-linux.default = pkgs.mkShell {
        NIX_CONFIG = "experimental-features = nix-command flakes";
        VAULT_ADDR = "https://vault.server01.lan";
        shellHook = ''
          alias gs="git status"
          alias gaa="git add --all"
          alias gcm="git commit -m"
          echo ""
          echo "Welcome to NixOS deployment shell"
          echo "================================="
          echo ""
          echo "Getting Started"
          echo "---------------"
          echo ""
          echo " 1. Use 'export VAULT_TOKEN=\$TOKEN' to set your vault token"
          echo ""
        '';
        nativeBuildInputs = with pkgs; [
          curl
          git
          jq
          sops
          ssh-to-age
          unstable.vault
        ];
      };

      packages.x86_64-linux.install-system = pkgs.writeShellApplication {
        name = "install-system";
        runtimeInputs = with pkgs; [
          curl
          git
          jq
          tree
          rsync
          nixos-anywhere
        ];
        text = builtins.readFile ./utils/remote-install.sh;
      };

      packages.x86_64-linux.vault-hostkey = pkgs.writeShellApplication {
        name = "vault-hostkey";
        runtimeInputs = with pkgs; [
          curl
          git
          jq
          openssh
          tree
          unstable.vault
        ];
        text = builtins.readFile ./utils/vault-hostkey.sh;
      };

      packages.x86_64-linux.vault-age = pkgs.writeShellApplication {
        name = "vault-age";
        runtimeInputs = with pkgs; [
          age
          curl
          git
          jq
          tree
          ssh-to-age
        ];
        text = builtins.readFile ./utils/vault-age.sh;
      };

      packages.x86_64-linux.vault-age-sops = pkgs.writeShellApplication {
        name = "vault-age-sops";
        runtimeInputs = with pkgs; [
          age
          curl
          git
          jq
          sops
          ssh-to-age
        ];
        text = builtins.readFile ./utils/vault-age-sops.sh;
      };

      packages.x86_64-linux.update-system = pkgs.writeShellApplication {
        name = "update-system";
        runtimeInputs = with pkgs; [
          deploy-rs
        ];
        text = builtins.readFile ./utils/update.sh;
      };

      nixosRoles = builtins.listToAttrs (map
        (f: {
          name = lib.strings.removeSuffix ".nix" "${f}";
          value = (./roles/nixos + "/${f}");
        })
        (lib.attrNames (filterExtension ".nix" (filterRegularFiles (builtins.readDir ./roles/nixos)))));

      homeManagerRoles = builtins.listToAttrs (map
        (f: {
          name = lib.strings.removeSuffix ".nix" "${f}";
          value = (./roles/home-manager + "/${f}");
        })
        (lib.attrNames (filterExtension ".nix" (filterRegularFiles (builtins.readDir ./roles/home-manager)))));

      nixosModules = {
        general = import ./modules/nixos/general;
        templates = import ./modules/nixos/templates;
      };

      homeManagerModules = {
        general = import ./modules/home-manager/general;
        templates = import ./modules/home-manager/templates;
      };
    };
}
