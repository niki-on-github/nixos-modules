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
      availableKernelModules = [ "nvme" "ahci" "xhci_pci" "usbhid" "usb_storage" "virtio_pci" "sr_mod" "virtio_blk" "sd_mod" "sdhci_pci" "aesni_intel" "cryptd" ];
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
}
