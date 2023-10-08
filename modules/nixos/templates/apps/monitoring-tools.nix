{ config, lib, pkgs, ... }:

let
  cfg = config.templates.apps.monitoring;
in
{
  options.templates.apps.monitoring = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Add monitoring tools.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      hddtemp
      htop
      inotify-tools
      iotop
      lm_sensors
      lsof
      nvtop
      powertop
      procps
      psmisc
      smartmontools
    ];
  };
}
