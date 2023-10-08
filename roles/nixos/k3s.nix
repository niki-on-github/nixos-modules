{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    general
    templates
  ];

  config = {
    templates = {
      services = {
        ssh = {
          enable = true;
        };
      };
      apps = {
        monitoring.enable = true;
      };
    };
  };
}
