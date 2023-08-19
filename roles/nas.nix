{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    general
    monitoring-tools
    samba
    ssh
    storage-volumes
    smartd-webui
  ];
}
