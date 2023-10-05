{ pkgs, lib, inputs, nixpkgs-unstable, ... }:

{
  imports = [
    ./apps/firefox.nix
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "spotify"
  ];

  home.packages = with pkgs; [
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
}
