{ config, lib, pkgs, nixpkgs-unstable, ... }:
with lib;
let
  cfg = config.templates.services.kvm;
in
{
  options.templates.services.kvm = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable KVM virtualisation.";
    };
    gui.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable GUI.";
    };
    # e.g. use command `sudo lspci -nn | grep VGA`
    # the hw id is inside the square brackets e.g. [1002:7340]
    vfioIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "The hardware IDs to pass through to a virtual machine.";
    };
    platform = lib.mkOption {
      type = lib.types.enum [ "amd" "intel" ];
      default = "amd";
      description = "CPU platform.";
    };
    machineUnits = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "The systemd *.scope units to wait for before starting Scream.";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "nix";
      description = "username";
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      dconf.enable = true;
      virt-manager.enable = true;
    };

    boot = {
      kernelModules = [
        "kvm-${cfg.platform}"
        "vfio_virqfd"
        "vfio_pci"
        "vfio_iommu_type1"
        "vfio"
      ];
      kernelParams = [
        "${cfg.platform}_iommu=on"
        "${cfg.platform}_iommu=pt"
        "kvm.ignore_msrs=1"
      ];
      extraModprobeConfig = optionalString (length cfg.vfioIds > 0)
        "options vfio-pci ids=${concatStringsSep "," cfg.vfioIds}";
    };

    systemd.tmpfiles.rules = [
      "f /dev/shm/looking-glass 0660 ${cfg.user} qemu-libvirtd -"
      "f /dev/shm/scream 0660 ${cfg.user} qemu-libvirtd -"
      "d /var/lib/libvirt/images 0775 root qemu-libvirtd -"
    ];

    systemd.services."libvirt-default-pool" = {
      wantedBy = [ "multi-user.target" ];
      requires = [  "libvirtd.service" ];
      script = ''
        ${pkgs.coreutils}/bin/sleep 30
        ${pkgs.libvirt}/bin/virsh --connect qemu:///system pool-define-as default dir --target /var/lib/libvirt/images >/dev/null 2>&1 || true
        ${pkgs.libvirt}/bin/virsh --connect qemu:///system pool-start default >/dev/null 2>&1 || true
        ${pkgs.libvirt}/bin/virsh --connect qemu:///system pool-autostart default >/dev/null 2>&1 || true
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        RestartSec = "1m";
        RemainAfterExit = true;
      };
    };

    environment.systemPackages = with pkgs; lib.mkMerge [ 
      [
        libvirt
        swtpm
        cdrtools
        bridge-utils
        dnsmasq
        ebtables
        dmidecode
        terraform
        packer
        virt-manager
        libosinfo
        osinfo-db
        libxslt
        quickemu
        nixos-generators
        virtnbdbackup
      ]
      (lib.mkIf cfg.gui.enable [
        looking-glass-client
        virt-viewer
      ])
    ];

    home-manager.users."${cfg.user}" = {
      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      };
    };

    virtualisation = {
      spiceUSBRedirection.enable = true;
      libvirtd = {
        enable = true;
        extraConfig = ''
          user="${cfg.user}"
        '';

        onBoot = "ignore";
        onShutdown = "shutdown";

        qemu = {
          package = pkgs.qemu_full;
          ovmf.enable = true;
          swtpm.enable = true;
          runAsRoot = false;
          verbatimConfig = ''
            namespaces = []
            user = "+${builtins.toString config.users.users.${cfg.user}.uid}"
          '';
        };
      };
    };

    users = {
      users = {
        ${cfg.user} = {
          extraGroups = [
            "qemu-libvirtd"
            "libvirtd"
            "disk"
          ];
        };
      };
    };

    systemd.user.services.scream-ivshmem = lib.mkIf cfg.gui.enable {
      enable = true;
      description = "Scream";
      serviceConfig = {
        ExecStart = "${pkgs.scream}/bin/scream -n scream -o pulse -m /dev/shm/scream";
        Restart = "always";
      };
      wantedBy = [ "multi-user.target" ];
      requires = [
        "libvirtd.service"
        "pipewire-pulse.service"
        "pipewire.service"
        "sound.target"
      ];
    };
  };
}
