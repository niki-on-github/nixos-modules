{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    libvirt
    virtmanager
  ];

  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
  };
}
