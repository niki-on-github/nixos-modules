{ inputs, ... }: {
  imports = with inputs.self.homeManagerModules; [
    general
    templates
  ];

  config = {
    templates = {
      home = {
        desktop.enable = true;
      };
    };

    # TODO why does spcifing this in module has no effect?
    programs = {
      zsh = {
        enable = true;
        dotDir = ".config/zsh";
      };
    };
  };
}
