{ pkgs, lib, ... }:
let
  disk-formater = ''
    disk=$(ls /dev/disk/by-id | grep -E "(^ata-)" | grep -Ev "(-part[1-9])" | ${pkgs.fzf}/bin/fzf --prompt "Disk: ")
    [ -n "$disk" ] || exit 0
    disk_dev=$(readlink -f "/dev/disk/by-id/$disk")
    type=$(echo -e "data\nparity" | ${pkgs.fzf}/bin/fzf --prompt "Type: ")
    [ -n "$type" ] || exit 1
    config="/etc/disk-formater/''${type}-disk.nix"
    [ -f $config ] || exit 1
    echo "current partition layout:"
    lsblk -P -p -o "name,label,partlabel,mountpoint,size" | grep "$disk_dev" | xargs -I {} echo " - {}"
    echo "disk: $disk_dev"
    read -p "label: " label
    echo "create $type partition layout on $disk ($disk_dev) with label $label"
    read -p "Continue execution with capital 'YES': " confirm
    [ "$confirm" = "YES" ] || exit 1
    sudo nix \
      --extra-experimental-features nix-command \
      --extra-experimental-features flakes \
      run github:nix-community/disko/7b186e0f812a7c54a1fa86b8f7c0f01afecc69c2 -- \
        $config \
        --mode format \
        --root-mountpoint / \
        --arg device "/dev/disk/by-id/$disk" \
        --argstr label $label
  '';

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
in
{
  environment = {

    etc = builtins.listToAttrs (generate-configs ./storage-configs "disk-formater");

    systemPackages = with pkgs; [
      btrfs-progs
      mergerfs
      smartmontools
      snapper
      snapraid
      snapraid-btrfs
      (writeShellScriptBin "disk-formater" "${disk-formater}")
    ];
  };
}
