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

    # https://nixos.wiki/wiki/Appimage
    boot.binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
    };

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
      xwayland.enable = true;
      zsh.enable = true;
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
      jack.enable = true;
    };

    hardware.pulseaudio = {
      enable = false;
      package = pkgs.pulseaudioFull;
      support32Bit = true;
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
