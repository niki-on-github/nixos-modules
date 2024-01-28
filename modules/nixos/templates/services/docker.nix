{ config, lib, pkgs, ... }:

let
  cfg = config.templates.services.docker;
in
{
  options.templates.services.docker = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable docker services.";
    };
    dns = lib.mkOption {
      type = lib.types.str;
      description = "dns ip";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "nix";
      description = "username";
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.docker-network = ''
      ${pkgs.docker}/bin/docker network create docker-bridge 2>/dev/null || true
    '';
    environment = {
      systemPackages = with pkgs; [
        docker
      ];
    };
    users = {
      users = {
        ${cfg.user} = {
          extraGroups = [
            "docker"
          ];
        };
      };
    };
    virtualisation = {
      docker = {
        enable = true;
        # storageDriver = "btrfs";
        # check file with systemctl status docker and get the path of `Drop-In` and check the file content
        daemon.settings = {
          dns =  ["${cfg.dns}" "8.8.8.8"];
          default-address-pools =  [
            {base="172.16.0.0/12"; size=24;}
          ];
        };
      };
    };
  };
}
