# Usage

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

    deploy-rs = {
      url = "github:serokell/deploy-rs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    personalModules = {
      url = "git+https://git.server01.lan/r/nixos-modules.git";
    };
  };
  outputs = { self, nixpkgs, nixpkgs-unstable, deploy-rs, home-manager, sops-nix, disko, personalModules, ... } @ inputs:
    let
      inherit (nixpkgs) lib;
      overlays = lib.flatten [
        personalModules.overlays
        personalModules.pkgs
      ];
      nixosDeployments = personalModules.utils.deploy.generateNixosDeployments {
        inherit inputs;
        path = ./systems;
        ssh-user = "nix";
        sharedModules = [
          { nixpkgs.overlays = overlays; }
          sops-nix.nixosModules.sops
          disko.nixosModules.disko
        ];
      };
    in
    {
      inherit (personalModules) formatter devShells packages nixosModules homeManagerModules nixosRoles;
      inherit (nixosDeployments) nixosConfigurations deploy checks;
    };
}
```
