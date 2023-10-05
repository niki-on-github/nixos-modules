{ pkgs, ... }:

{
  networking.networkmanager.enable = true;

  hardware.opengl.enable = true;

  services = {
    dbus.enable = true;
    udisks2.enable = true;
    atd.enable = true;
  };

  programs = {
    nm-applet = {
      enable = true;
      indicator = false;
    };
    dconf.enable = true;
  };


  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      at
      networkmanagerapplet
      xdg-utils
      libnotify
      libappindicator
      libsForQt5.qt5ct
      libsForQt5.breeze-qt5
      libsForQt5.breeze-gtk
    ];
  };
}
