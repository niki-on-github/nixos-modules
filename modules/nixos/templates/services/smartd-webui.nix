{ config, lib, pkgs, ... }:

let
  cfg = config.templates.services.smartdWebui;
in
{
  options.templates.services.smartdWebui = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable smartd webui services.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.scrutiny = {
      image = "ghcr.io/analogj/scrutiny:v0.7.1-omnibus";
      ports = [ "0.0.0.0:8080:8080" ];
      volumes = [
        "/dev:/dev"
        "/run/udev:/run/udev"
        "scrutiny_influxdb2:/opt/scrutiny/influxdb"
        "scrutiny_config:/opt/scrutiny/config"
      ];
      extraOptions = [
        "--privileged"
        "--cap-add=SYS_RAWIO"
        "--cap-add=SYS_ADMIN"
      ];
    };
  };
}
