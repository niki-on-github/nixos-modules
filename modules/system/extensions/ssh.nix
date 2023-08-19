{
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  networking.firewall.allowedTCPPorts = [ 22 ];

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
      };
    };
  };
}
