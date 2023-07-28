final: prev:
{
  spice-vdagent = prev.spice-vdagent.overrideAttrs (old: rec {
    version = "0.22.1";
    src = prev.fetchurl {
      url = "https://www.spice-space.org/download/releases/${old.pname}-${version}.tar.bz2";
      sha256 = "93b0d15aca4762cc7d379b179a7101149dbaed62b72112fffb2b3e90b11687a0";
    };
  });
}
