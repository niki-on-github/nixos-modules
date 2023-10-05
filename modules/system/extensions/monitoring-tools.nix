{ pkgs, ... }:
{
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
}
