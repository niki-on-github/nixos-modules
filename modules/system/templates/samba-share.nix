{ lib, pool, ... }:
let
  pathPrefix = "/pool";

  generateShares = pool: (map
    (volume: {
      name = "${pool.name}-${volume}";
      value = {
        "path" = "${pathPrefix}/${pool.name}/volume/${volume}";
        "browseable" = "yes";
        "writable" = "yes";
        "guest ok" = "no";
        "public" = "no";
        "force group" = "users";
      };
    })
    pool.volumes);

  myShares = generateShares pool;
in
{
  services.samba.shares = builtins.listToAttrs myShares;
}
