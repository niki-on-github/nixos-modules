{ config, lib, pkgs, ... }:

let
  cfg = config.templates.services.samba;
in
{
  options.templates.services.samba = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Samba Services.";
    };
    shares = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "share name";
          };
          path = lib.mkOption {
            type = lib.types.str;
            description = "share path";
          };
          hostsAllow = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16";
            description = "acress control on ip address level";
          };
        };
      });
      default = [ ];
      description = "Samba shares";
    };
  };

  config = lib.mkIf cfg.enable {
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
      shares = builtins.listToAttrs (map
        (volume: {
          name = "${volume.name}";
          value = {
            "path" = "${volume.path}";
            "browseable" = "yes";
            "writable" = "yes";
            "guest ok" = "no";
            "public" = "no";
            "force group" = "users";
            "hosts allow" = "${volume.hostsAllow}";
            "hosts deny" = "0.0.0.0/0";
          };
        })
        cfg.shares
      );
    };

    networking.firewall = {
      allowedTCPPorts = [ 445 139 ];
      allowedUDPPorts = [ 137 138 ];
    };

    environment = {
      systemPackages = with pkgs; [
        cifs-utils
      ];
    };
  };
}
