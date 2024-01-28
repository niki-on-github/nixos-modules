{ config, lib, pkgs, nixpkgs-unstable, ... }:
let
  cfg = config.templates.home.desktop;

  generateFiles = files: (map
    (f: {
      name = "${f}";
      value = {
        source = ./dotfiles + "/${f}";
      };
    })
    files
  );

  generateDirectoriesRecursive = directories: (map
    (d: {
      name = "${d}";
      value = {
        source = ./dotfiles + "/${d}";
        recursive = true;
      };
    })
    directories
  );

  filterFileType = type: file:
    (lib.filterAttrs (name: type': type == type') file);

  filterExcludeExtension = extension: file:
    (lib.filterAttrs (name: value: !(lib.hasSuffix extension name)) file);

  filterRegularFiles = filterFileType "regular";

  filterDirectories = filterFileType "directory";

  dotfiles = (generateFiles (lib.attrNames (filterExcludeExtension ".lock" (filterExcludeExtension ".nix" (filterRegularFiles (builtins.readDir ./dotfiles)))))) ++ (generateDirectoriesRecursive(lib.attrNames (filterDirectories (builtins.readDir ./dotfiles))));
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
    
    home.file = builtins.listToAttrs dotfiles;

    systemd.user.targets.tray = {
  		Unit = {
  			Description = "Home Manager System Tray";
  			Requires = [ "graphical-session-pre.target" ];
  		};
  	};
  
    services = {
      udiskie = {
        enable = true;
        tray = "always";
        automount = false;
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
      pavucontrol
      pulsemixer
      easyeffects
    ] ++ [
      udiskie
      nixpkgs-unstable.alacritty
      foot
      tk
      meld
      mpc-cli
      mpv
      ffmpeg_6-full
      ncmpcpp
      imv
      veracrypt
      android-file-transfer
      newsboat
      obs-studio
      nur.repos.nltch.spotify-adblock
      thunderbird
      vopono
      openvpn
      krita
      gparted
      zathura
      filezilla
    ];
  }   
  // import (./desktop-programs.nix) { inherit config lib pkgs; });
}
