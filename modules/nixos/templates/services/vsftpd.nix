{ config, lib, pkgs, ... }:

let
  cfg = config.templates.services.ftp;
in
{
  options.templates.services.ftp = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ftp services.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.vsftpd = {
      enable = true;
      writeEnable = true;
      localUsers = true;
      extraConfig = ''
        pasv_enable=Yes
        pasv_min_port=51000
        pasv_max_port=51999
      '';
    };

    networking.firewall.allowedTCPPorts = [ 21 ];
    networking.firewall.allowedTCPPortRanges = [{ from = 51000; to = 51999; }];
  };
}
