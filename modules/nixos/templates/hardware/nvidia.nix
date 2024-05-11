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
  };
  config = lib.mkIf cfg.enable {
    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "nvidia-x11"
        "nvidia-settings"
      ];

    services.xserver.videoDrivers = ["nvidia"];
    boot.initrd.kernelModules = [ "nvidia" ];
    boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];

    hardware.nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    nixpkgs.config.cudaSupport = true;

    environment = {
        systemPackages = with pkgs; [
            cudatoolkit
            libGLU
            libGL
            ncurses5
            linuxPackages.nvidia_x11
        ];

        sessionVariables = {
            LD_LIBRARY_PATH = ["${config.hardware.nvidia.package}/lib"];
            CUDA_PATH = "${pkgs.cudatoolkit}";
        };
    };
  };
}