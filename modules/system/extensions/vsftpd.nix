{ lib, pkgs, config, ... }:
{
  config = {
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
