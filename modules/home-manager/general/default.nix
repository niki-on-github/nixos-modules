{ config, inputs, ... }:

{
  config = {
    news.display = "silent";
    systemd.user.startServices = true;
    home.stateVersion = "23.05";
  };
}
