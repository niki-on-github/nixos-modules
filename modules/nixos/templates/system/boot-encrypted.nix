{ config, lib, pkgs, ... }:

let
  cfg = config.templates.system.bootEncrypted;
in
{
  options.templates.system.bootEncrypted = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Encypted System Boot.";
    };
    disk = lib.mkOption {
      type = lib.types.str;
      description = "Encrypted Disk e.g. /dev/disk/by-id/ata-ssd";
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot/efi";
        };
        grub = {
          enable = true;
          device = "nodev";
          efiSupport = true;
          enableCryptodisk = true;
          extraPrepareConfig = ''
            if [ -t 0 ] ; then
              ${pkgs.cryptsetup}/bin/cryptsetup luksOpen --test-passphrase /dev/disk/by-partlabel/luks_system --key-file /boot/keys/disk.key || ${pkgs.cryptsetup}/bin/cryptsetup luksAddKey /dev/disk/by-partlabel/luks_system /boot/keys/disk.key
            fi
            chmod 000 /boot/keys
          '';
        };
      };

      kernelParams = [
        "boot.shell_on_fail"
      ];

      initrd = {
        availableKernelModules = [ "nvme" "ahci" "xhci_pci" "usbhid" "usb_storage" "virtio_pci" "sr_mod" "virtio_blk" "virtio-scsi" "sd_mod" "sdhci_pci" "aesni_intel" "cryptd" ];
        luks.devices.system = {
          allowDiscards = true;
          keyFile = "/disk.key";
          preLVM = true;
          fallbackToPassword = true;
        };

        secrets = {
          "disk.key" = "/boot/keys/disk.key";
        };
      };
    };

    disko.devices.disk = lib.genAttrs [ "${cfg.disk}" ] (dev: {
      device = dev;
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
    });
  };
}
