{ pkgs, ... }:
{
  nix = {
    # TODO enable this when all machines are updated 
    # package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 60d";
    };

    optimise = {
      automatic = true;
      dates = [ "20:00" ];
    };
  };
}
