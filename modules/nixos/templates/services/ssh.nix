{ config, lib, pkgs, ... }:

let
  cfg = config.templates.services.ssh;
in
{
  options.templates.services.ssh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ssh services.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 22 ];

    services = {
      openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
        };
      };
    };
  };
}
