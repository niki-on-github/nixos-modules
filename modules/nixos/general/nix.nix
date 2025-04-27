{ pkgs, ... }:
{
  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    settings.download-buffer-size = 524288000;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 120d";
    };

    optimise = {
      automatic = true;
      dates = [ "20:00" ];
    };
  };
}
