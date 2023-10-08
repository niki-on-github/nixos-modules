{
  imports = [
    ./apps/modern-unix.nix
    ./apps/monitoring-tools.nix
    ./services/k3s.nix
    ./services/kvm.nix
    ./services/nvidia-docker.nix
    ./services/printer.nix
    ./services/samba.nix
    ./services/smartd-webui.nix
    ./services/ssh.nix
    ./services/vsftpd.nix
    ./system/boot-encrypted.nix
    ./system/crypttab.nix
    ./system/desktop.nix
    ./system/storage-pools
  ];
}
