{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "replicate-cog";
  version = "0.6.1";
  src = fetchurl {
    url = "https://github.com/replicate/cog/releases/download/v0.6.1/cog_Linux_x86_64";
    sha256 = "1ja0br48vfj6ggvgx3a3dgnjdkpsw07n9qw244h4v8cvdbcfh50f";
  };
  phases = ["installPhase" "patchPhase"];
  installPhase = ''
    mkdir -p $out/bin
    cp -f $src $out/bin/cog
    chmod +x $out/bin/cog
  '';
}
