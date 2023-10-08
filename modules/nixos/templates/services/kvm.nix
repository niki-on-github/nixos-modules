{ config, lib, pkgs, ... }:
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
    ];

    environment.systemPackages = with pkgs; [
      looking-glass-client
      libvirt
      virt-manager
      swtpm
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
      libvirtd = {
        enable = true;
        extraConfig = ''
          user="${cfg.user}"
        '';

        onBoot = "ignore";
        onShutdown = "shutdown";

        qemu = {
          package = pkgs.qemu_kvm;
          ovmf.enable = true;
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

    systemd.user.services.scream-ivshmem = {
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
