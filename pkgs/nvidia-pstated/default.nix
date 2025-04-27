{ pkgs, ...  }:
let
  dependencies = with pkgs; [
    cudatoolkit
    cudaPackages.cuda_nvml_dev
    linuxPackages.nvidia_x11
  ];
  libPath = pkgs.lib.makeLibraryPath dependencies;
  binPath = pkgs.lib.makeBinPath dependencies;
in
  pkgs.stdenv.mkDerivation {
    pname = "nvidia-pstated";
    version = "1.0.6";
    src = pkgs.fetchgit {
      url = "https://github.com/niki-on-github/nvidia-pstated.git";
      rev = "0e82e75327c9c5379aa54224ea42f0a15fe7704f";
      sha256 = "sha256-gzOK8ISoL+vqxJMfNgTaZCknXT7G6jsFjWIgKI30m+I=";
    };
    cmakeFlags = [ "-Wno-dev" "--compile-no-warning-as-error" "-DCFLAGS=-Wno-error" "-DCXXFLAGS=-Wno-error" ];
    buildInputs = dependencies;
    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
      makeWrapper
    ];
    postInstall = ''
      wrapProgram "$out/bin/nvidia-pstated" --prefix LD_LIBRARY_PATH : "${libPath}" --prefix PATH : "${binPath}"
    '';
}
