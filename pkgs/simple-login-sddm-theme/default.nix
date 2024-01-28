{ lib
, pkgs
, stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation
rec {
  pname = "simple-login-sddm-theme";
  version = "1.0.0";
  dontBuild = true;
  src = fetchFromGitHub {
    owner = "niki-on-github";
    repo = "simple-login-sddm-theme";
    rev = "032fd57a59233f1fe95a498954d884c3beb7414a";
    sha256 = "sha256-theaCZxtH67FhN3dT0NAQr/zFbBkvT6kzWY5hKJJK9o=";
  };
  nativeBuildInputs = with pkgs.libsForQt5.qt5; [
    wrapQtAppsHook
    qtbase
    qtsvg
    qtgraphicaleffects
    qtquickcontrols2
  ];

  propagatedUserEnvPkgs = with pkgs.libsForQt5.qt5; [
    qtbase
    qtsvg
    qtgraphicaleffects
    qtquickcontrols2
  ];

  installPhase = ''
    mkdir -p $out/share/sddm/themes
    cp -aR $src $out/share/sddm/themes/simple-login-sddm-theme
  '';

}
