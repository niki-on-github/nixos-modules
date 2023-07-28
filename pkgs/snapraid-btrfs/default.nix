{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "snapraid-btrfs";
  version = "0.14.2";
  src = fetchFromGitHub {
    owner = "automorphism88";
    repo = "snapraid-btrfs";
    rev = "8cdbf54100c2b630ee9fcea11b14f58a894b4bf3";
    # nix-prefetch-url --unpack https://github.com/<owner>/<repo>/archive/<rev>.tar.gz
    sha256 = "02mj59gw54yj22n8gjsfj6g1lsx07nsg5laxks75ihccjkkhn211";
  };

  phases = [ "installPhase" "patchPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cp -f $src/snapraid-btrfs $out/bin/snapraid-btrfs
    sed -i 's/#!\/bin\/bash -/#!\/usr\/bin\/env bash/g' $out/bin/snapraid-btrfs
    chmod +x $out/bin/snapraid-btrfs
  '';
}
