{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    cups
    ghostscript
    gscan2pdf
    gutenprint
    system-config-printer
  ];

  services.printing.enable = true;
}
