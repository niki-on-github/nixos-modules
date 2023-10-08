{ config, lib, pkgs, ... }:

let
  cfg = config.templates.system.desktop;
in
{
  options.templates.system.desktop = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Desktop services.";
    };
  };

  config = lib.mkIf cfg.enable {
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

    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    hardware.pulseaudio = {
      enable = false;
      package = pkgs.pulseaudioFull;
      support32Bit = true;
    };

    programs = {
      xwayland.enable = true;
      zsh.enable = true;
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
  };
}
