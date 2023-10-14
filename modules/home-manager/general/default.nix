{ config, pkgs, inputs, ... }:

{
  config = {
    news.display = "silent";
    systemd.user.startServices = true;
    home.stateVersion = "23.05";
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
