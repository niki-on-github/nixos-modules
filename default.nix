{ pkgs ? import <nixpkgs> { } }:

let
  lib = pkgs.lib;
in
(lib.recurseIntoAttrs
  (lib.mapAttrs
    (src: _:
      pkgs.callPackage (./pkgs + "/${src}/default.nix") { })
    (builtins.readDir ./pkgs)))
