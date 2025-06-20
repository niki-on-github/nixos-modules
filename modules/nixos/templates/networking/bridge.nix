{ config, lib, ... }:

let
  cfg = config.templates.networking;
in
{
  options.templates.networking = {
    bridges = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "bridge name e.g. br1";
          };
          interfaces = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "interfaces to assign to this bridge";
          };
          ip = lib.mkOption {
            type = lib.types.str;
            description = "ip for the bridge";
          };
          subnet = lib.mkOption {
            type = lib.types.int;
            default = 24;
            description = "network subnet";
          };
          gateway = lib.mkOption {
            type = lib.types.str;
            default = "10.0.1.1";
            description = "gateway ip";
          };
          dns = lib.mkOption {
            type = lib.types.str;
            default = "10.0.1.1";
            description = "dns ip";
          };
        };
      });
      default = [ ];
      description = "Bridges";
    };
  };

  config = lib.mkIf (cfg.bridges != []) {
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    networking = {
      bridges = lib.listToAttrs (map (bridge: {
        name = bridge.name;
        value = {
          interfaces = bridge.interfaces;
        };
      }) cfg.bridges);

      interfaces = lib.listToAttrs (map (bridge: {
        name = bridge.name;
        value = {
          useDHCP = false;
          ipv4.addresses = [{
            address = bridge.ip;
            prefixLength = bridge.subnet;
          }];
        };
      }) cfg.bridges);
    };

    systemd.network = {
      enable = true;
      networks = lib.listToAttrs (map (bridge: {
        name = "40-${bridge.name}";
        value = {
          matchConfig.Name = bridge.name;
          networkConfig = {
            DHCP = "no";
            Address = "${bridge.ip}/${toString bridge.subnet}";
            Gateway = bridge.gateway;
            DNS = bridge.dns;
          };
          linkConfig = {
            RequiredForOnline = "no";
          };
        };
      }) cfg.bridges);
    };

    networking.networkmanager.enable = true;
    systemd.network.wait-online.enable = false;
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
