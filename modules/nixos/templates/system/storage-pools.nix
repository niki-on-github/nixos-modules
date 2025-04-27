{ config, pkgs, lib, ... }:
# NOTE: We have to add the encrypted disks to the crypttab config becaus stage 1 luks unlock will not find drives connected to the LSI HBA
let
  cfg = config.templates.system.storagePools;

  getDir = dir: lib.mapAttrs
    (file: type:
      if type == "directory" then getDir "${dir}/${file}" else file
    )
    (builtins.readDir dir);

  files = dir: lib.collect lib.isString (lib.mapAttrsRecursive (path: type: lib.concatStringsSep "/" path) (getDir dir));

  generate-configs = src: dest: (map
    (file: {
      name = "${dest}/${file}";
      value = {
        mode = "0555";
        source = builtins.toPath "${src}/${file}";
      };
    })
    (files src));

  generateDataDiskEntries = pool: (map
    (item: {
      name = "${cfg.poolPathPrefix}/${pool.name}/disks/data/${item.label}";
      value = {
        depends = [ "/dev/mapper/${item.label}" ];
        device = "/dev/mapper/${item.label}";
        fsType = "btrfs";
        options = [ "subvol=@data" "compress=zstd" "noatime" "nofail" ];
      };
    })
    pool.dataDisks);

  generateDataSnapshotDiskEntries = pool: (map
    (item: {
      name = "${cfg.poolPathPrefix}/${pool.name}/disks/data/${item.label}/.snapshots";
      value = {
        depends = [ "/dev/mapper/${item.label}" ];
        device = "/dev/mapper/${item.label}";
        fsType = "btrfs";
        options = [ "subvol=@snapshots" "compress=zstd" "noatime" "nofail" ];
      };
    })
    pool.dataDisks);

  generateParityDiskEntries = pool: (map
    (item: {
      name = "${cfg.poolPathPrefix}/${pool.name}/disks/parity/${item.label}";
      value = {
        depends = [ "/dev/mapper/${item.label}" ];
        device = "/dev/mapper/${item.label}";
        fsType = "btrfs";
        options = [ "subvol=@parity" "compress=zstd" "noatime" "nofail" ];
      };
    })
    pool.parityDisks);

  generateContentDiskEntries = pool: (map
    (item: {
      name = "${cfg.poolPathPrefix}/${pool.name}/disks/content/${item.label}";
      value = {
        depends = [ "/dev/mapper/${item.label}" ];
        device = "/dev/mapper/${item.label}";
        fsType = "btrfs";
        options = [ "subvol=@content" "compress=zstd" "noatime" "nofail" ];
      };
    })
    (pool.dataDisks ++ pool.parityDisks));

  generateVolumeEntries = pool: (map
    (volume: {
      name = "${cfg.poolPathPrefix}/${pool.name}/volume/${volume}";
      value = {
        depends = (map (item: "${cfg.poolPathPrefix}/${pool.name}/disks/data/${item.label}") pool.dataDisks);
        device = "${cfg.poolPathPrefix}/${pool.name}/disks/data/*/${volume}";
        fsType = "fuse.mergerfs";
        options = [ "defaults" "allow_other" "minfreespace=25G" "fsname=${pool.name}_${volume}" "category.create=mfs" ];
      };
    })
    pool.volumes);

  generateSnapraidConfigs = pool: [{
    name = "snapraid_${pool.name}.conf";
    value = {
      mode = "0555";
      text = ''
        # Parity disks
        ${lib.strings.concatStringsSep "\n" (lib.lists.imap1 (i: disk: "${toString i}-parity ${cfg.poolPathPrefix}/${pool.name}/disks/parity/${disk.label}/snapraid.parity") pool.parityDisks)}

        # Content file locations
        # SnapRAID will need the content file to build a recovery. Multiple copies of this file are essential for maximum data safety!
        ${lib.strings.concatStringsSep "\n" (lib.lists.forEach pool.dataDisks (disk: "content ${cfg.poolPathPrefix}/${pool.name}/disks/content/${disk.label}/snapraid.content"))}
        ${lib.strings.concatStringsSep "\n" (lib.lists.forEach pool.parityDisks (disk: "content ${cfg.poolPathPrefix}/${pool.name}/disks/content/${disk.label}/snapraid.content"))}

        # Data disks
        # The order of disks is relevant for parity!
        ${lib.strings.concatStringsSep "\n" (lib.lists.imap1 (i: disk: "data d${toString i} ${cfg.poolPathPrefix}/${pool.name}/disks/data/${disk.label}") pool.dataDisks)}

        # Excluded files and directories
        exclude /.snapshots/
        exclude *.unrecoverable
        exclude /lost+found/
      '';
    };
  }];

  generateSnapperConfigs = pool: (map
    (disk: {
      name = "${pool.name}-${disk.label}";
      value = {
        SUBVOLUME = "${cfg.poolPathPrefix}/${pool.name}/disks/data/${disk.label}";
        ALLOW_GROUPS = [ "wheel" ];
        TIMELINE_CREATE = false;
      };
    })
    pool.dataDisks);

  generatePoolVolumeDataPaths = pool: (lib.lists.forEach (lib.cartesianProduct { v = pool.volumes; d = (map (x: x.label) pool.dataDisks); }) (item: "d ${cfg.poolPathPrefix}/${pool.name}/disks/data/${item.d}/${item.v} 0775 root users -"));
  setPoolContentPermissions = pool: (lib.lists.forEach (pool.dataDisks ++ pool.parityDisks) (item: "d ${cfg.poolPathPrefix}/${pool.name}/disks/content/${item.label} 0775 root users -"));
  setPoolParityPermissions = pool: (lib.lists.forEach (pool.parityDisks) (item: "d ${cfg.poolPathPrefix}/${pool.name}/disks/parity/${item.label} 0775 root users -"));
  setPoolSnapshotPermissions = pool: (lib.lists.forEach (pool.dataDisks) (item: "d ${cfg.poolPathPrefix}/${pool.name}/disks/data/${item.label}/.snapshots 0755 root users -"));

  generateSnapraidAlias = pool: (pkgs.writeShellScriptBin "snapraid-${pool.name}" ''
    # TODO how to access snapper snapshots wthout root?
    if [ "$EUID" -ne 0 ] ; then
      echo "Please run as root"
      exit
    fi
    lsblk
    snapraid-btrfs -c /etc/snapraid_${pool.name}.conf $@
  '');

  myDataDisks = builtins.concatLists (map (pool: generateDataDiskEntries pool) cfg.pools);
  myDataSnapshotDisks = builtins.concatLists (map (pool: generateDataSnapshotDiskEntries pool) cfg.pools);
  myParityDisks = builtins.concatLists (map (pool: generateParityDiskEntries pool) cfg.pools);
  myContentDisks = builtins.concatLists (map (pool: generateContentDiskEntries pool) cfg.pools);
  myVolumes = builtins.concatLists (map (pool: generateVolumeEntries pool) cfg.pools);
  mySnapraidConfigs = builtins.concatLists (map (pool: generateSnapraidConfigs pool) cfg.pools);
  mySnapperConfigs = builtins.concatLists (map (pool: generateSnapperConfigs pool) cfg.pools);
  myPoolVolumePaths = builtins.concatLists (map (pool: generatePoolVolumeDataPaths pool) cfg.pools);
  mySnapraidAliases = (map (pool: generateSnapraidAlias pool) cfg.pools);
  myPoolContentPermissions = builtins.concatLists (map (pool: setPoolContentPermissions pool) cfg.pools);
  myPoolParityPermissions = builtins.concatLists (map (pool: setPoolParityPermissions pool) cfg.pools);
  myPoolSnapshotPermissions = builtins.concatLists (map (pool: setPoolSnapshotPermissions pool) cfg.pools);
in
{
  options.templates.system.storagePools = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable storage-pools.";
    };
    samba = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable samba share for storage-pools.";
    };
    poolPathPrefix = lib.mkOption {
      type = lib.types.str;
      default = "/pool";
      description = "Pools path prefix";
    };
    keyFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/secrets/disk.key";
      description = "crypttab keyfile";
    };
    pools = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "pool name";
          };
          volumes = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "pool volumes";
          };
          dataDisks = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                blkDev = lib.mkOption {
                  type = lib.types.str;
                  description = "block device path";
                };
                label = lib.mkOption {
                  type = lib.types.str;
                  description = "mount label";
                };
              };
            });
            default = [ ];
            description = "Data Disks";
          };
          parityDisks = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                blkDev = lib.mkOption {
                  type = lib.types.str;
                  description = "block device path";
                };
                label = lib.mkOption {
                  type = lib.types.str;
                  description = "mount label";
                };
              };
            });
            default = [ ];
            description = "Parity Disks";
          };
        };
      });
      default = [ ];
      description = "Storage Volume Pools";
    };
  };

  config = lib.mkIf cfg.enable {

    templates = {
      services.samba = lib.mkIf cfg.samba {
        enable = true;
        shares = builtins.concatLists (map
          (pool: (map
            (volume: { name = "${pool.name}-${volume}"; path = "${cfg.poolPathPrefix}/${pool.name}/volume/${volume}"; })
            pool.volumes)
          ) 
          cfg.pools
        );
      };
      system = {
        crypttab.devices = (builtins.concatLists (map
          (pool: (map
            (disk: { blkDev = disk.blkDev; label = disk.label; })
            pool.dataDisks)
          ) 
          cfg.pools
        )) ++ (builtins.concatLists (map
          (pool: (map
            (disk: { blkDev = disk.blkDev; label = disk.label; })
            pool.parityDisks)
          ) 
          cfg.pools
        ));
       storage = {
          enable = true;
          keyFile = cfg.keyFile;
       };
      };
    };

    systemd = {
      tmpfiles = {
        rules = myPoolVolumePaths ++ myPoolContentPermissions ++ myPoolParityPermissions ++ myPoolSnapshotPermissions;
      };

      services.storage-pools-setup = {
        description = "Ensure directories exist after mounts";
        wantedBy = [ "multi-user.target" ];
        after = [ "local-fs.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 15";
          ExecStart = "${pkgs.systemd}/bin/systemd-tmpfiles --create";
        };
      };
    };

    fileSystems = builtins.listToAttrs (myDataDisks ++ myDataSnapshotDisks ++ myParityDisks ++ myContentDisks ++ myVolumes);

    services = {
     snapper = {
        configs = builtins.listToAttrs mySnapperConfigs;
      };
    };

    environment = {
      etc = builtins.listToAttrs mySnapraidConfigs;
      systemPackages = with pkgs; [
        btrfs-progs
        disko
        mergerfs
        smartmontools
        snapper
        snapraid
        snapraid-btrfs
      ] ++ mySnapraidAliases;
    };
  };
}
