{
    nix.settings = {
        substituters = [
            "https://cache.nixos.org?priority=2"
            "https://nix-community.cachix.org?priority=3"
            "https://cuda-maintainers.cachix.org?priority=4"
        ];
        trusted-substituters = [
            "https://cache.saumon.network/proxmox-nixos"
            "https://ncps.k8s.lan?priority=1&trusted=1"
        ];
        trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
            "proxmox-nixos:nveXDuVVhFDRFx8Dn19f1WDEaNRJjPrF2CPD2D+m1ys="
            "ncps.k8s.lan:aa83xD69W+YSvIpQGZaTp+aoze+94c5DG4I+Atjyll5JouKumXqO/CI89uzI1GaVTMh6MhD9EIv5BLIOqd/Mng=="
        ];
    };
}
