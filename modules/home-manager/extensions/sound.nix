{ pkgs, inputs, nixpkgs-unstable, ... }:

{
  home.packages = with pkgs; [
    pamixer
    pulsemixer
    easyeffects
  ];
}
