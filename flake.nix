{
  description = "My NixOS modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... } @ inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

      overlays = (lib.mapAttrsToList
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
          gnupg
          sops
          ssh-to-age
          ssh-to-pgp
          vault
        ];
      };

      packages.x86_64-linux.install-system = pkgs.writeShellApplication {
        name = "install-system";
        runtimeInputs = with pkgs; [
          curl
          git
          gnupg
          jq
          sops
          ssh-to-pgp
          vault
        ];
        text = builtins.readFile ./utils/remote-install.sh;
      };

      packages.x86_64-linux.create-secret = pkgs.writeShellApplication {
        name = "create-secret";
        runtimeInputs = with pkgs; [
          curl
          git
          gnupg
          jq
          sops
          ssh-to-pgp
          vault
        ];
        text = builtins.readFile ./utils/create-secret.sh;
      };

      packages.x86_64-linux.update-system = pkgs.writeShellApplication {
        name = "update-system";
        text = builtins.readFile ./utils/remote-update.sh;
      };

      nixosRoles = import ./roles;

      nixosModules = {
        general = import ./modules/system/general;
        boot-encrypted = import ./modules/system/extensions/boot-encrypted.nix;
        samba = import ./modules/system/extensions/samba.nix;
        ssh = import ./modules/system/extensions/ssh.nix;
        storage-volumes = import ./modules/system/extensions/storage-volumes.nix;
        encrypted-system-disk-template = import ./modules/system/templates/encrypted-system-disk.nix;
        samba-share-template = import ./modules/system/templates/samba-share.nix;
        storage-pool-template = import ./modules/system/templates/storage-pool.nix;
        k3s = import ./modules/system/extensions/k3s.nix;
        monitoring-tools = import ./modules/system/extensions/monitoring-tools.nix;
        smartd-webui = import ./modules/system/extensions/smartd-webui.nix;
      };

      homeManagerModules = {
        general = import ./modules/home-manager/general;
        k3s = import ./modules/home-manager/extensions/k3s.nix;
      };
    };
}
