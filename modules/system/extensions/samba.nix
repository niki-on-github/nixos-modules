{ lib, pkgs, config, ... }:
{
  config = {
    # add smb user with `sudo smbpasswd -a nixos`
    services.samba = {
      enable = true;
      enableNmbd = false;
      enableWinbindd = false;
      extraConfig = ''
        workgroup = WORKGROUP
        server string = NixOS Samba Server
        server role = standalone server
        log file = /var/log/samba/smbd_%m.log
        security = user
        max log size = 50
        dns proxy = no
        load printers = no
        printcap name = /dev/null
      '';
    };

    networking.firewall.allowedTCPPorts = [ 445 139 ];
    networking.firewall.allowedUDPPorts = [ 137 138 ];

    environment = {
      systemPackages = with pkgs; [
        cifs-utils
      ];
    };
  };
}
