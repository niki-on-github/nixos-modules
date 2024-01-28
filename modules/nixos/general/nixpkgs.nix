{ lib, config, pkgs, inputs, ... }:
{
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = (_: true);
  };

  environment = {
    systemPackages = with pkgs; [
      git
      vim
      openssh
      parted
    ];
  };

  environment.etc."current-system-packages".text =
    let
      packages = builtins.map (p: "${p.name}") (config.environment.systemPackages);
      sortedUnique = builtins.sort builtins.lessThan (lib.unique packages);
      formatted = builtins.concatStringsSep "\n" sortedUnique;
    in
    formatted;
}
