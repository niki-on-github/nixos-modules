{ config, pkgs, lib, ... }:
let
  cfg = config.templates.system.storage;

  disk-formater = keyfile: ''
    if [ "$EUID" -ne 0 ] ; then
      echo "Please run as root"
      exit 1
    fi
    if [ ! -e ${keyfile} ]; then
      echo "keyfile ${keyfile} not found"
      exit 1
    fi
    disk=$(ls /dev/disk/by-id | grep -E "(^ata-)" | grep -Ev "(-part[1-9])" | ${pkgs.fzf}/bin/fzf --prompt "Disk: ")
    [ -n "$disk" ] || exit 0
    disk_dev=$(readlink -f "/dev/disk/by-id/$disk")
    type=$(echo -e "data\nparity" | ${pkgs.fzf}/bin/fzf --prompt "Type: ")
    [ -n "$type" ] || exit 1
    echo "current partition layout:"
    lsblk -P -p -o "name,label,partlabel,mountpoint,size" | grep "$disk_dev" | xargs -I {} echo " - {}"
    echo "disk: $disk_dev"
    read -p "label: " label
    echo "create $type partition layout on $disk ($disk_dev) with label $label"
    read -p "Continue execution with capital 'YES': " confirm
    [ "$confirm" = "YES" ] || exit 1
    ${pkgs.util-linux}/bin/wipefs --force --quiet --all /dev/disk/by-id/$disk
    ${pkgs.parted}/bin/parted --script /dev/disk/by-id/$disk mklabel gpt
    ${pkgs.parted}/bin/parted --script /dev/disk/by-id/$disk mkpart primary 1MiB 100% name 1 luks_$label
    ${pkgs.cryptsetup}/bin/cryptsetup luksFormat --batch-mode /dev/disk/by-id/$disk-part1 ${keyfile}
    echo "Add Passphrase to luks volume:"
    ${pkgs.cryptsetup}/bin/cryptsetup luksAddKey /dev/disk/by-id/$disk-part1 -d ${keyfile}
    ${pkgs.cryptsetup}/bin/cryptsetup open /dev/disk/by-id/$disk-part1 $label --key-file ${keyfile}
    ${pkgs.btrfs-progs}/bin/mkfs.btrfs -f -L $label /dev/mapper/$label
    tmp_path=/tmp/btrfs-root-disk-formater
    mkdir -p $tmp_path
    mount -t btrfs -o defaults,noatime,compress=zstd /dev/mapper/$label $tmp_path
    ${pkgs.btrfs-progs}/bin/btrfs subvolume create "$tmp_path/@content"
    ${pkgs.btrfs-progs}/bin/btrfs subvolume create "$tmp_path/@$type"
    ${pkgs.btrfs-progs}/bin/btrfs subvolume create "$tmp_path/@snapshots"
    sync
    sleep 1
    umount -A -v -f /dev/mapper/$label
    sleep 1
    ${pkgs.cryptsetup}/bin/cryptsetup luksClose $label
    rm -d $tmp_path
    echo "/dev/disk/by-id/$disk is now provisioned"
  '';
  in
{
  options.templates.system.storage = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable storage tools";
    };
    keyFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/secrets/disk.key";
      description = "crypttab keyfile";
    };
  };
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [
       (pkgs.writeShellScriptBin "disk-formater" "${disk-formater cfg.keyFile}")
      ];
    };

  };
}
