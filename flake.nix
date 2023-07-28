{
  description = "My NixOS modules";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs, ... } @ inputs:
  let
    lib = nixpkgs.lib;
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
in
  {
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
    };
  };
}
