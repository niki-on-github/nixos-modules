{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "snapraid-btrfs";
  version = "0.14.2";
  src = fetchFromGitHub {
    owner = "niki-on-github";
    repo = "snapraid-btrfs";
    rev = "daac842b4dec734747ac6e638c32deeb6d5d918b";
    # nix-prefetch-url --unpack https://github.com/<owner>/<repo>/archive/<rev>.tar.gz
    sha256 = "09z3dm7snqjr41x3g03f4cl02nf9750kshjc9cvhdw57xfrnilgp";
  };

  phases = [ "installPhase" "patchPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cp -f $src/snapraid-btrfs $out/bin/snapraid-btrfs
    chmod +x $out/bin/snapraid-btrfs
  '';
}
