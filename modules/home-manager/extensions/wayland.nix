{ pkgs, inputs, nixpkgs-unstable, ... }:

{
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
  };

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
  ];
}
