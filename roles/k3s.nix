{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    general
    k3s
    monitoring-tools
    ssh
  ];
}
