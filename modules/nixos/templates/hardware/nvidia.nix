{ config, lib, pkgs, ... }:

let
  cfg = config.templates.hardware.nvidia;
in
{
  options.templates.hardware.nvidia = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable nvida drivers.";
    };
    pstated = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable a daemon that automatically manages the performance states of NVIDIA GPUs.";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      nvidia-container-toolkit.enable = true;
      nvidia = {
        modesetting.enable = true;
        nvidiaSettings = true;
        open = false;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };
    };

    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "nvidia-x11"
        "nvidia-settings"
      ];

    systemd.services.nvidia-pstated = lib.mkIf cfg.pstated {
      description = "A daemon that automatically manages the performance states of NVIDIA GPUs";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        DynamicUser = true;
        ExecStart = "${pkgs.nvidia-pstated}/bin/nvidia-pstated";
        Restart = "on-failure";
        RestartSec = "2s";
        StartLimitIntervalSec = 0;
      };
      enable = true;
    };

    services.xserver.videoDrivers = ["nvidia"];
    boot.initrd.kernelModules = [ "nvidia" ];
    boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];

    nixpkgs.config.cudaSupport = true;

    environment = {
        systemPackages = with pkgs; [
            cudatoolkit
            libGLU
            libGL
            ncurses5
            linuxPackages.nvidia_x11
            nvidia-pstated
        ];

        sessionVariables = {
            LD_LIBRARY_PATH = ["${config.hardware.nvidia.package}/lib"];
            CUDA_PATH = "${pkgs.cudatoolkit}";
        };
    };
  };
}
