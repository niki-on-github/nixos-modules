{ device, ... }: {
  disko.devices = {
    disk = {
      data = {
        device = builtins.toPath device;
        type = "disk";
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            {
              name = "boot";
              start = "1MiB";
              end = "128MiB";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                extraArgs = [ "-F32" ];
                mountpoint = "/boot/efi";
                mountOptions = [
                  "defaults"
                ];
              };
            }
            {
              name = "luks_system";
              start = "128MiB";
              end = "100%";
              content = {
                type = "luks";
                name = "system";
                extraFormatArgs = [ "--type luks1" "--pbkdf-force-iterations 500000" ];
                extraOpenArgs = [ "--type luks1" "--allow-discards" ];
                additionalKeyFiles = [ "/tmp/disk.key" ];
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/@" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/@home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/@log" = {
                      mountpoint = "/var/log";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/@swap" = {
                      mountpoint = "/swap";
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
