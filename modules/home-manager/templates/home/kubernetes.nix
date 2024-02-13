{ config, lib, pkgs, ... }:
let
  cfg = config.templates.home.kubernetes;
in
{
  options.templates.home.kubernetes = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable home-manager kubernetes module";
    };
  };

  config = lib.mkIf cfg.enable {
     programs.k9s = {
      enable = true;
      settings = {
        k9s = {
          logger = {
            tail = 100;
            buffer = 5000;
            sinceSeconds = 50000;
            textWrap = true;
            showTime = true;
          };
          thresholds = {
            cpu = {
              critical = 90;
              warn = 80;
            };
            memory = {
              critical = 90;
              warn = 80;
            };
          };
          cluster.default.namespace.active = "all";
        };
      };
    };
  };
}
