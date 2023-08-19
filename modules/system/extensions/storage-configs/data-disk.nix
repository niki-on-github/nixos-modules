{ device, label, ... }: {
  disko.devices = {
    disk = {
      data = {
        type = "disk";
        device = builtins.toPath device;
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            {
              name = "luks_${label}";
              start = "1MiB";
              end = "100%";
              content = {
                type = "luks";
                name = "${label}";
                extraOpenArgs = [ ];
                additionalKeyFiles = [ "/boot/keys/disk.key" ];
                initrdUnlock = false;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" "-L" "${label}" ];
                  subvolumes = {
                    "/@content" = {
                      mountpoint = "/mnt/pools/pool-01/disks/content/${label}";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/@data" = {
                      mountpoint = "/mnt/pools/pool-01/disks/data/${label}";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/@snapshots" = {
                      mountpoint = "/mnt/pools/pool-01/disks/data/${label}/.snapshots";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                  };
                };
              };
            }
          ];
        };
      };
    };
  };
}
