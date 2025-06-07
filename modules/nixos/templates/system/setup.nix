{ config, lib, pkgs, ... }:

let
  cfg = config.templates.system.setup;
  
  mkEnableIfElse = a : b: yes: no: lib.mkMerge [
    (lib.mkIf (a && b) yes)
    (lib.mkIf (a && !b) no)
  ];
in
{
  options.templates.system.setup = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable System Setup.";
    };
    encryption = lib.mkOption {
      type = lib.types.enum [ "disabled" "system" "full" ];
      default = "disabled";
      description = ''
        Specifies the disk encryption strategy for the system:
        - "disabled": No encryption (default)
        - "system": Encrypt only the system partition
        - "full": Full disk encryption (including boot partition)
      '';
    };
    disk = lib.mkOption {
      type = lib.types.str;
      description = "Disk e.g. /dev/disk/by-id/ata-ssd";
    };
  };

  config = mkEnableIfElse cfg.enable (cfg.encryption == "disabled") {
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
          configurationLimit = 10;
        };
      };

      kernelParams = [
        "boot.shell_on_fail"
      ];

      initrd = {
        availableKernelModules = [ "nvme" "ahci" "xhci_pci" "usbhid" "usb_storage" "virtio_pci" "sr_mod" "virtio_blk" "virtio-scsi" "sd_mod" "sdhci_pci" "aesni_intel" "cryptd" ];
      };
    };
    
    disko.devices.disk = lib.genAttrs [ "${cfg.disk}" ] (dev: {
      device = dev;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            label = "boot";
            size = "256M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              extraArgs = [ "-F32" ];
              mountpoint = "/boot/efi";
              mountOptions = [
                "defaults"
              ];
            };
          };
          system = {
            label = "system";
            size = "100%";
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
        };
      };
    }); 
  } {
    # full/system encrypted configuration
    systemd.tmpfiles.rules = [
      "d /etc/secrets 0000 root root - -"
      "z /etc/secrets 0000 root root - -"
    ];
    boot = {
      loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = lib.mkMerge [
              (lib.mkIf (cfg.encryption == "system") "/boot")
              (lib.mkIf (cfg.encryption == "full") "/boot/efi")
            ];
        };
        grub = {
          enable = true;
          device = "nodev";
          efiSupport = true;
          enableCryptodisk = true;
          configurationLimit = 10;
          extraPrepareConfig = ''
            if [ -t 0 ] ; then
              ${pkgs.cryptsetup}/bin/cryptsetup luksOpen --test-passphrase /dev/disk/by-partlabel/luks_system --key-file /etc/secrets/disk.key || ${pkgs.cryptsetup}/bin/cryptsetup luksAddKey /dev/disk/by-partlabel/luks_system /etc/secrets/disk.key
            fi
            chmod 000 /etc/secrets
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
          keyFile = lib.mkIf (cfg.encryption == "full") "/disk.key";
          preLVM = true;
          fallbackToPassword = true;
        };

        secrets = lib.mkIf (cfg.encryption == "full") {
          "disk.key" = "/etc/secrets/disk.key";
        };
      };
    };

    disko.devices.disk = lib.genAttrs [ "${cfg.disk}" ] (dev: {
      device = dev;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            label = "boot";
            size = if (cfg.encryption == "full") then "256M" else "4096M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              extraArgs = [ "-F32" ];
              mountpoint = lib.mkMerge [
                (lib.mkIf (cfg.encryption == "system") "/boot")
                (lib.mkIf (cfg.encryption == "full") "/boot/efi")
              ];
              mountOptions = [
                "defaults"
              ];
            };
          };
          luks_system = {
            label = "luks_system";
            size = "100%";
            content = {
              type = "luks";
              name = "system";
              extraFormatArgs = [ "--type luks1" "--pbkdf-force-iterations 500000" ];
              extraOpenArgs = [ "--type luks1" "--allow-discards" ];
              additionalKeyFiles = [ "/tmp/disk.key" ]; # NOTE: We use nixos-anywhere with this key setup location
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
          };
        };
      };
    });

  };
}
