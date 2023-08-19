{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    du-dust
    htop
    iotop
    lsof
    nvtop
    powertop
    smartmontools
  ];
}
