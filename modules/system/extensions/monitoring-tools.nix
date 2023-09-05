{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    du-dust
    file
    htop
    iotop
    lm_sensors
    lsof
    nvtop
    powertop
    psmisc
    smartmontools
  ];
}
