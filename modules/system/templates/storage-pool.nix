{ lib, pkgs, pool, ... }:
let

  pathPrefix = "/pool";
  diskKeyFile = "/mnt-root/boot/disk.key";

  generateDataDiskEntries = pool: (map
    (item: {
      name = "${pathPrefix}/${pool.name}/disks/data/${item.label}";
      value = {
        device = "/dev/mapper/${item.label}";
        fsType = "btrfs";
        options = [ "subvol=@data" "compress=zstd" "noatime" "nofail" ];
        encrypted = {
          enable = true;
          label = "${item.label}";
          blkDev = "${item.blkDev}";
          keyFile = "${diskKeyFile}";
        };
      };
    })
    pool.dataDisks);

  generateDataSnapshotDiskEntries = pool: (map
    (item: {
      name = "${pathPrefix}/${pool.name}/disks/data/${item.label}/.snapshots";
      value = {
        device = "/dev/mapper/${item.label}";
        fsType = "btrfs";
        options = [ "subvol=@snapshots" "compress=zstd" "noatime" "nofail" ];
        encrypted = {
          enable = true;
          label = "${item.label}";
          blkDev = "${item.blkDev}";
          keyFile = "${diskKeyFile}";
        };
      };
    })
    pool.dataDisks);

  generateParityDiskEntries = pool: (map
    (item: {
      name = "${pathPrefix}/${pool.name}/disks/parity/${item.label}";
      value = {
        device = "/dev/mapper/${item.label}";
        fsType = "btrfs";
        options = [ "subvol=@parity" "compress=zstd" "noatime" "nofail" ];
        encrypted = {
          enable = true;
          label = "${item.label}";
          blkDev = "${item.blkDev}";
          keyFile = "${diskKeyFile}";
        };
      };
    })
    pool.parityDisks);

  generateContentDiskEntries = pool: (map
    (item: {
      name = "${pathPrefix}/${pool.name}/disks/content/${item.label}";
      value = {
        device = "/dev/mapper/${item.label}";
        fsType = "btrfs";
        options = [ "subvol=@content" "compress=zstd" "noatime" "nofail" ];
        encrypted = {
          enable = true;
          label = "${item.label}";
          blkDev = "${item.blkDev}";
          keyFile = "${diskKeyFile}";
        };
      };
    })
    (pool.dataDisks ++ pool.parityDisks));

  generateVolumeEntries = pool: (map
    (volume: {
      name = "${pathPrefix}/${pool.name}/volume/${volume}";
      value = {
        depends = (map (item: "${pathPrefix}/${pool.name}/disks/data/${item.label}") pool.dataDisks);
        device = "${pathPrefix}/${pool.name}/disks/data/*/${volume}";
        fsType = "fuse.mergerfs";
        options = [ "defaults" "allow_other" "minfreespace=50G" "fsname=${pool.name}_${volume}" ];
      };
    })
    pool.volumes);

  generateSnapraidConfigs = pool: [{
    name = "snapraid_${pool.name}.conf";
    value = {
      mode = "0555";
      text = ''
        # Parity disks
        ${lib.strings.concatStringsSep "\n" (lib.lists.imap1 (i: disk: "${toString i}-parity ${pathPrefix}/${pool.name}/disks/parity/${disk.label}/snapraid.parity") pool.parityDisks)}

        # Content file locations
        # SnapRAID will need the content file to build a recovery. Multiple copies of this file are essential for maximum data safety!
        ${lib.strings.concatStringsSep "\n" (lib.lists.forEach pool.dataDisks (disk: "content ${pathPrefix}/${pool.name}/disks/content/${disk.label}/snapraid.content"))}
        ${lib.strings.concatStringsSep "\n" (lib.lists.forEach pool.parityDisks (disk: "content ${pathPrefix}/${pool.name}/disks/content/${disk.label}/snapraid.content"))}

        # Data disks
        # The order of disks is relevant for parity!
        ${lib.strings.concatStringsSep "\n" (lib.lists.imap1 (i: disk: "data d${toString i} ${pathPrefix}/${pool.name}/disks/data/${disk.label}") pool.dataDisks)}

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
        SUBVOLUME = "${pathPrefix}/${pool.name}/disks/data/${disk.label}";
        ALLOW_GROUPS = [ "wheel" ];
        TIMELINE_CREATE = false;
      };
    })
    pool.dataDisks);

  generatePoolVolumeDataPaths = pool: (lib.lists.forEach (lib.cartesianProductOfSets { v = pool.volumes; d = (map (x: x.label) pool.dataDisks); }) (item: "d ${pathPrefix}/${pool.name}/disks/data/${item.d}/${item.v} 0775 root users -"));

  generateSnapraidAlias = pool: (pkgs.writeShellScriptBin "snapraid-${pool.name}" ''
    snapraid-btrfs -c /etc/snapraid_${pool.name}.conf $@
  '');

  myDataDisks = generateDataDiskEntries pool;
  myDataSnapshotDisks = generateDataSnapshotDiskEntries pool;
  myParityDisks = generateParityDiskEntries pool;
  myContentDisks = generateContentDiskEntries pool;
  myVolumes = generateVolumeEntries pool;
  mySnapraidConfigs = generateSnapraidConfigs pool;
  mySnapperConfigs = generateSnapperConfigs pool;
  myPoolVolumePaths = generatePoolVolumeDataPaths pool;
  mySnapraidAlias = generateSnapraidAlias pool;

in
{
  config = {
    systemd.tmpfiles.rules = myPoolVolumePaths;
    environment.etc = builtins.listToAttrs mySnapraidConfigs;
    fileSystems = builtins.listToAttrs (myDataDisks ++ myDataSnapshotDisks ++ myParityDisks ++ myContentDisks ++ myVolumes);
    services.snapper.configs = builtins.listToAttrs mySnapperConfigs;
    environment.systemPackages = [
      mySnapraidAlias
    ];
  };
}
