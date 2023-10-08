{ inputs, ... }: {
  imports = with inputs.self.homeManagerModules; [
    general
    templates
  ];

  config = {
    templates = {
      home = {
        kubernetes.enable = true;
      };
    };
  };
}
