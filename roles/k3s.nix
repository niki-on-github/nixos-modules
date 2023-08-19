{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    general
    ssh
    k3s
  ];
}
