{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    docker
    nvidia-docker
    replicate-cog
  ];

  # required for virtualisation.docker.enableNvidia
  hardware.opengl.driSupport32Bit = true;

  virtualisation = {
    docker = {
      enable = true;
      enableNvidia = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
  };
}
