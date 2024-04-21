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
      apcupsd
      inotify-tools
      iotop
      lm_sensors
      lsof
      powertop
      procps
      psmisc
      usbutils
      pciutils
      smartmontools
    ];
  };
}
