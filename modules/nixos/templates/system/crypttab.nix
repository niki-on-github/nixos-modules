{ config, lib, pkgs, ... }:

let
  cfg = config.templates.system.crypttab;
in
{
  options.templates.system.crypttab = {
    keyfile = lib.mkOption {
      type = lib.types.str;
      default = "/boot/keys/disk.key";
      description = "Path to keyfile";
    };
    devices = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf (lib.types.submodule {
        blkDev = lib.mkOption {
          type = lib.types.str;
          description = "block device path";
        };
        label = lib.mkOption {
          type = lib.types.str;
          description = "mount label";
        };
        mountpoint = lib.mkOption {
          type = lib.types.str;
          description = "mountpoint for decypted volume";
        };
        fsType = lib.mkOption {
          type = lib.types.str;
          description = "filesystem type";
        };
        mountOptions = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "noatime" "nofail" ];
          description = "mount options";
        };
      }));
      default = [ ];
      description = "Encrypted Disks";
    };
  };

  config = {
    environment.etc."crypttab" = {
      mode = "600";
      text = lib.mkDefault (lib.mkAfter ''
        ${lib.strings.concatStringsSep "\n" (lib.lists.forEach (cfg.devices) (disk: "${disk.label} ${disk.blkDev} ${cfg.keyFile} nofail"))}
      '');
    };
    fileSystems = builtins.listToAttrs (map
      (item: {
        name = "${item.mountpoint}";
        value = {
          depends = [ "/dev/mapper/${item.label}" ];
          device = "/dev/mapper/${item.label}";
          fsType = "${item.fsType}";
          options = item.mountOptions;
        };
      })
      cfg.devices
    );
  };
}
