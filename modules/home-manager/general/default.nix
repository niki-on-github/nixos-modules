{ ... }:

{
  config = {
    news.display = "silent";
    systemd.user.startServices = true;

    # the gpg-agent in nixos somptimes start hanging and nothing works until restart pc, restarting service etc do not solve the problem!
    # but we dont need it anyway so diable it for now
    #services.gpg-agent = {
    #  enable = true;
    #  enableSshSupport = true;
    #};
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
