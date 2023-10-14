{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    general
    templates
  ];

  config = {
    templates = {
      system = {
        desktop = {
          enable = true;
        };
      };
      services = {
        ssh = {
          enable = true;
        };
      };
      apps = {
        modernUnix.enable = true;
        monitoring.enable = true;
      };
    };
  };
}
