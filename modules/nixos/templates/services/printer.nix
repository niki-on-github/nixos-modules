{ config, lib, pkgs, ... }:

let
  cfg = config.templates.services.printer;
in
{
  options.templates.services.printer = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable printer services.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cups
      ghostscript
      gscan2pdf
      gutenprint
      system-config-printer
    ];

    services.printing.enable = true;
  };
}
