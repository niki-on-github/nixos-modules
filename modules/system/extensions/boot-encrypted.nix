{ lib, pkgs, ... }:

{
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
          if [ ! -f /boot/disk.key ]; then
            dd bs=512 count=8 if=/dev/random of=/boot/disk.key iflag=fullblock
          fi
          ${pkgs.cryptsetup}/bin/cryptsetup luksOpen --test-passphrase /dev/disk/by-partlabel/luks_system --key-file /boot/disk.key || ${pkgs.cryptsetup}/bin/cryptsetup luksAddKey /dev/disk/by-partlabel/luks_system /boot/disk.key
          chmod 000 /boot/disk.key
        '';
      };
    };

    kernelParams = [
      "boot.shell_on_fail"
    ];

    # TODO pathExists does not work here
    initrd = {
      availableKernelModules = [ "nvme" "ahci" "xhci_pci" "usbhid" "usb_storage" "virtio_pci" "sr_mod" "virtio_blk" "sd_mod" "sdhci_pci" "aesni_intel" "cryptd" ];
      luks.devices.system = {
        allowDiscards = true;
        keyFile = if builtins.pathExists /boot/disk.key then "/disk.key" else null;
        preLVM = true;
        fallbackToPassword = true;
      };

      secrets = lib.mkIf (builtins.pathExists /boot/disk.key) {
        "disk.key" = "/boot/disk.key";
      };
    };
  };
}
