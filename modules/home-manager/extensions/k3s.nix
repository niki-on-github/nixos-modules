{ lib, config, pkgs, ... }:
{
  config = {
    xdg.configFile."k9s/config.yml".source = ./config/k9s/config.yml;
    systemd.user.tmpfiles.rules =  [
      "d ${config.home.homeDirectory}/.kube 0755 ${config.home.username} users -"
      "L ${config.home.homeDirectory}/.kube/config  - - - - /etc/rancher/k3s/k3s.yaml"
    ];
  };
}
