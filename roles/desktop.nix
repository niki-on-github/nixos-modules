{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    general
    ssh
    sound
    printer
    monitoring-tools
    modern-unix
    desktop
  ];
}
