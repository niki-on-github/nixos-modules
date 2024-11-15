{
  lib,
  stdenv,
  fetchzip,
  fetchFromGitHub,
  alsa-lib,
  autoPatchelfHook,
  brotli,
  ffmpeg,
  libdrm,
  libGL,
  libunwind,
  libva,
  libvdpau,
  libxkbcommon,
  nix-update-script,
  openssl,
  pipewire,
  pulseaudio,
  vulkan-loader,
  wayland,
  x264,
  xorg,
  gtk3,
  cairo,
  openvr,
  xvidcore,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "alxr";
  version = "0.45.1";

  src = fetchzip {
    url = "https://github.com/michael-mueller-git/ALXR-nightly/releases/download/v${finalAttrs.version}%2Bnightly.2024.08.04/alvr_server_linux.tar.gz";
    # 1. nix-prefetch-url --unpack "https://github.com/michael-mueller-git/ALXR-nightly/releases/download/v0.45.1%2Bnightly.2024.08.04/alvr_server_linux.tar.gz" 
    # 2. nix hash to-sri --type sha256 $BASE64_HASH
    hash = "sha256-iCXTaXrQoHwXg6MUGYz7n8/k+bWFmWV9OjEkm9ye+hA=";
    stripRoot=false;
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  runtimeDependencies = [
    brotli
    ffmpeg
    libdrm
    libGL
    libxkbcommon
    openssl
    pipewire
    pulseaudio
    wayland
    x264
    gtk3
    cairo
    openvr
    xorg.libX11
    xorg.libXcursor
    xorg.libxcb
    xorg.libXi
  ];

  buildInputs = [
    alsa-lib
    libunwind
    libva
    libvdpau
    vulkan-loader
  ] ++ finalAttrs.runtimeDependencies;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/applications
    cp -r $src/* $out

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    description = "Stream VR games from your PC to your headset via Wi-Fi";
    homepage = "https://github.com/korejan/ALVR";
    changelog = "https://github.com/korejan/ALVR/releases/tag/v${finalAttrs.version}";
    license = licenses.mit;
    maintainers = with maintainers; [];
    platforms = platforms.linux;
    mainProgram = "alvr_launcher";
  };
})
