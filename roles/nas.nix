{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    general
    monitoring-tools
    samba
    smartd-webui
    ssh
    storage-volumes
    vsftpd
  ];
}
