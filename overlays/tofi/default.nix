self: super:
{
  tofi = super.tofi.overrideAttrs (old: rec {
    version = "0.9.2";

    src = super.fetchFromGitHub {
      owner = "philj56";
      repo = "tofi";
      rev = "b32c9954d3da430392575e9e637a2d8d114e34d0";
      # nix-prefetch-url --unpack https://github.com/philj56/tofi/archive/b32c9954d3da430392575e9e637a2d8d114e34d0.tar.gz
      sha256 = "0b60jsmjw3ln96qp7y6dwa5s33i8zh5428kxkm2afkhmjh9lrwyq";
    };
  });
}
