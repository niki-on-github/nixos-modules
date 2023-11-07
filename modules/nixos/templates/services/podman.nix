{ config, lib, pkgs, ... }:

let
  cfg = config.templates.services.podman;
in
{
  options.templates.services.podman = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable podman services.";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "nix";
      description = "username";
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        podman
        podman-compose
      ];
    };
    users = {
      users = {
        ${cfg.user} = {
          extraGroups = [
            "podman"
          ];
        };
      };
    };
    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };
  };
}
