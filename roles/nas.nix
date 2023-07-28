{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    inputs.home-manager.nixosModules.home-manager
    general
    ssh
    storage-volumes
    samba
  ];
}
