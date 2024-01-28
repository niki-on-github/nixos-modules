{
  systemd = {
    extraConfig = ''
      DefaultTimeoutStopSec=25s
    '';
    tmpfiles.rules = [
      "z /etc/ssh/ssh_host_ed25519_key 0600 root root - -"
      "z /etc/ssh/ssh_host_ed25519_key.pub 0644 root root - -"
      "z /etc/ssh/ssh_host_rsa_key 0600 root root - -"
      "z /etc/ssh/ssh_host_rsa_key.pub 0644 root root - -"
    ];
  };
}
