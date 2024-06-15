{ lib, ... }:

rec {

  readVisible = path:
    lib.filterAttrs (name: value: !(lib.hasPrefix "." name))
      (builtins.readDir path);

  filterFileType = type: dir:
    lib.attrNames (lib.filterAttrs (name: type': type == type') dir);

  filterRegularFiles = filterFileType "regular";

  filterDirectories = filterFileType "directory";

  readVisibleDirectories = path: filterDirectories (readVisible path);

  generateNixosDeployments = { inputs, path, ssh-user, sharedModules ? [ ], deployOptions ? { } }:
    let
      systems = readVisibleDirectories path;
      hosts = lib.concatMap
        (system:
          builtins.map (host: { inherit host system; })
            (readVisibleDirectories (path + "/${system}")))
        systems;
      hostModule = host: [{
        networking = {
          hostName = host;
          hostId = builtins.substring 0 8 (builtins.hashString "sha256" host);
        };
      }];
      buildConfig = { system, host }:
        lib.nameValuePair host (lib.nixosSystem {
          system = "${system}";
          modules =
            let
              defaults = { pkgs, ... }: {
                _module.args.nixpkgs-unstable = import inputs.nixpkgs-unstable { inherit (pkgs.stdenv.targetPlatform) system; config.allowUnfree = true; };
              };
            in
            lib.flatten [
              defaults
              [ (path + "/${system}/${host}") ]
              (hostModule host)
              sharedModules
            ];
          specialArgs = { inherit inputs; };
        });
      nixosConfigurations = lib.listToAttrs (builtins.map buildConfig hosts);

      buildDeployment = { host, ... }:
        lib.nameValuePair host {
          hostname = host;
          magicRollback = false; # enable this breaks sudo password see https://github.com/serokell/deploy-rs/issues/78
          sshUser = "${ssh-user}";
          sshOpts = [ "-o UserKnownHostsFile=/dev/null" "-o StrictHostKeyChecking=no" "-t" ];
          profiles.system = {
            user = "root";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos
              nixosConfigurations."${host}";
          };
        };
      deploy = {
        nodes = lib.listToAttrs (builtins.map buildDeployment hosts);
      } // deployOptions;
    in
    {
      inherit nixosConfigurations deploy;
      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks deploy)
        inputs.deploy-rs.lib;
    };
}
