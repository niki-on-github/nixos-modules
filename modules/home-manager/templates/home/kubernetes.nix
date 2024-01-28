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
            tail = 1000;
            buffer = 10000;
            sinceSeconds = 86400;
            textWrap = true;
            showTime = true;
          };
          cluster.default.namespace.active = "all";
        };
      };
    };
  };
}
