{ pkgs, config, ...  }:
let
  # TODO remove when available in stable
  pinned = import
    (builtins.fetchTarball {
      url = "https://github.com/nixos/nixpkgs/tarball/a8e75ef7d4c4825e789491dec55e161cc9a73d2d";
      sha256 = "sha256:0kfpz7jca4ql0m4qknwid1bnvkl6lblfnsfw5fwk8964wg114dkn";
    }){ config = config; system = "x86_64-linux"; };
  # python = pkgs.python311;
  python = pinned.python311;
  dependencies = [
    (python.withPackages (p: with p; [
      (libnbd.overrideAttrs { buildPythonBindings = python; })
      libvirt
      tqdm
      lz4
      lxml
      paramiko
      typing-extensions
      colorlog
    ]))
  ];
  libPath = pkgs.lib.makeLibraryPath dependencies;
  binPath = pkgs.lib.makeBinPath dependencies;
in
  pkgs.python311Packages.buildPythonPackage {
    pname = "virtnbdbackup";
    version = "2.1.0";
    src = pkgs.fetchgit {
      url = "https://github.com/abbbi/virtnbdbackup.git";
      rev = "v2.10";
      sha256 = "sha256-59dS00qKppqWv67oBO0lz0u0TT5aYThyUiMR00nYjzc=";
    };
    doCheck = false;
    propagatedBuildInputs = dependencies;
    nativeBuildInputs = with pkgs; [
      makeWrapper
    ];
    postInstall = ''
      wrapProgram "$out/bin/virtnbdbackup" --prefix LD_LIBRARY_PATH : "${libPath}" --prefix PATH : "${binPath}"
      wrapProgram "$out/bin/virtnbdrestore" --prefix LD_LIBRARY_PATH : "${libPath}" --prefix PATH : "${binPath}"
      wrapProgram "$out/bin/virtnbdmap" --prefix LD_LIBRARY_PATH : "${libPath}" --prefix PATH : "${binPath}"
    '';
  }

