{ lib
, pkgs
}:

let
  version = "v0.3.0";
  dependencies = with pkgs; [
    dbus
    gtk3
    glib
    restic
    webkitgtk
  ];
  libPath = lib.makeLibraryPath dependencies;
  binPath = lib.makeBinPath dependencies;

  restic-browser_frontend = pkgs.buildNpmPackage {
    pname = "restic-browser";
    version = "${version}";
    src = pkgs.fetchgit {
      url = "https://github.com/emuell/restic-browser.git";
      rev = "${version}";
      sha256 = "sha256-/7LDsNrHbE6JJZnFHWVMRBqXixqB8oEio2cUfIIHPsA=";
    };
    npmDepsHash = "sha256-i92LlC9/04x9vXoyo+TVc3yCiaOCgvE//lT6cJZuoBk=";
    buildInputs = with pkgs; [
      nodejs_22
      typescript
    ];
    installPhase = ''
      mkdir $out
      cp -r dist/ $out
    '';
  };

in
pkgs.rustPlatform.buildRustPackage {
  pname = "restic-browser";
  version = "${version}";
  src = pkgs.fetchgit {
    url = "https://github.com/emuell/restic-browser.git";
    rev = "${version}";
    sha256 = "sha256-/7LDsNrHbE6JJZnFHWVMRBqXixqB8oEio2cUfIIHPsA=";
  };
  sourceRoot = "restic-browser/src-tauri";
  cargoLock = {
    lockFile = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/emuell/restic-browser/${version}/src-tauri/Cargo.lock";
      sha256 = "sha256-Tfs7+s6TL/PREUZpDlWR2cvUrDbIeeD9mGNq+0EoA3Y";
    };
    allowBuiltinFetchGit = true;
  };
  doCheck = false;
  propagatedBuildInputs = dependencies;
  nativeBuildInputs = with pkgs; [
    pkg-config
    makeWrapper
    cargo
    cargo-tauri
  ];
  postPatch = ''
    substituteInPlace tauri.conf.json --replace '"beforeBuildCommand": "npm run build",' '"beforeBuildCommand": "",'
    substituteInPlace tauri.conf.json --replace '"distDir": "../dist"' '"distDir": "${restic-browser_frontend}/dist"'
  '';
  buildPhase = ''
    cargo tauri build
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp -r target/release/. $out/bin
    # NOTE: GDK_BACKEND=x11 is a workaround to get proper font scaling on wayland see https://github.com/tauri-apps/tauri/issues/7354
    wrapProgram "$out/bin/restic-browser" --set GDK_BACKEND x11 --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}" --prefix LD_LIBRARY_PATH : "${libPath}" --prefix PATH : "${binPath}"
  '';
}
