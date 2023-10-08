{ config, lib, pkgs, nixpkgs-unstable, ... }:
let
  cfg = config.templates.home.desktop;
in
{
  options.templates.home.desktop = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable home-manager desktop module";
    };
  };

  config = lib.mkIf cfg.enable ({
    services = {
      udiskie = {
        enable = true;
        tray = "always";
      };
      mako = {
        enable = true;
      };
      easyeffects = {
        enable = true;
      };
      mpd = {
        enable = true;
      };
      clipman = {
        enable = true;
      };
      syncthing = {
        enable = true;
      };
    };

    systemd.user.tmpfiles.rules = [
      "d ${config.home.homeDirectory}/.cache 0755 ${config.home.username} users -"
      "d ${config.home.homeDirectory}/.cache/mpd 0755 ${config.home.username} users -"
      "d ${config.home.homeDirectory}/.cache/mpd/playlists 0755 ${config.home.username} users -"
      "f ${config.home.homeDirectory}/.cache/mpd/database 0755 ${config.home.username} users -"
    ];

    programs = {
      zsh = {
        enable = true;
        dotDir = ".config/zsh";
      };
    };

    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "spotify"
    ];

    home.packages = with pkgs; [
      clipman
      grim
      mako
      slurp
      tofi
      wayvnc
      wev
      glib
      wf-recorder
      wl-clipboard
      wlr-randr
      nixpkgs-unstable.waybar
      wtype
      swaylock-effects
      swayidle
    ] ++ [
      pamixer
      pulsemixer
      easyeffects
    ] ++ [
      alacritty
      meld
      mpd
      mpv
      ncmpcpp
      qview
      newsboat
      obs-studio
      nur.repos.nltch.spotify-adblock
      thunderbird
      vopono
    ];
  } // import (./apps/firefox.nix) { inherit config lib pkgs; });
}
