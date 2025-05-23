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
    waydroid.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable waydroid services.";
    };
    sddm.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable display manager services.";
    };
    portals = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ pkgs.xdg-desktop-portal-gtk ];
      description = "xdg destkop portals";
    };
  };

  config = lib.mkIf cfg.enable {

    fonts = {
      packages = with pkgs; [
        ibm-plex
        jetbrains-mono
        hasklig
        hack-font

        material-design-icons
        material-icons

        powerline-fonts

        fira
        fira-mono
        fira-code
        fira-code-symbols

        noto-fonts
        noto-fonts-emoji
        noto-fonts-extra

        roboto
        roboto-mono
        roboto-slab

        anonymousPro
        corefonts
        source-code-pro
        symbola
        liberation_ttf

        (nerdfonts.override { fonts = [
          "JetBrainsMono"
          "SourceCodePro"
          "Hack"
        ]; })
      ];
    };

    # https://nixos.wiki/wiki/Appimage
    boot.binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
    };

    virtualisation = {
      waydroid = lib.mkIf cfg.waydroid.enable {
        enable = true;
      };
    };

    networking.networkmanager.enable = true;

    hardware.graphics.enable = true;
    services = {
      dbus.enable = true;
      udisks2.enable = true;
      atd.enable = true;
      flatpak.enable = true;
    };

    programs = {
      nm-applet = {
        enable = true;
        indicator = false;
      };
      dconf.enable = true;
      xwayland.enable = true;
      zsh.enable = true;
      thunar.enable = true;
    };

    xdg.autostart.enable = true;
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = cfg.portals;
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

    services.xserver = lib.mkIf cfg.sddm.enable {
      enable = true;
      displayManager.sddm = {
        enable = true;
        theme = "simple-login-sddm-theme";
      };
    };

    environment = {
      systemPackages = with pkgs; lib.mkMerge [ 
        [
          at
          networkmanagerapplet
          xdg-utils
          appimage-run
          libnotify
          libappindicator
          libsForQt5.breeze-gtk
          libsForQt5.breeze-qt5
          libsForQt5.qt5ct
          flatpak-builder
          adwaita-icon-theme
          shared-mime-info
        ]
        (lib.mkIf cfg.sddm.enable [
          simple-login-sddm-theme
        ])
      ];
      pathsToLink = [
        "/share/icons"
        "/share/mime"
      ];
    };
  };
}
