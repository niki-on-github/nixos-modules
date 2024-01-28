{ lib, config, pkgs, nixpkgs-unstable, ... }:

let
  cfg = config.templates.apps.modernUnix;
in
{
  options.templates.apps.modernUnix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Add modern-unix tools.";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "unrar"
    ];
    environment = {
      systemPackages = with pkgs; [
        age
        bat
        bc
        choose
        coreutils-full
        curlie
        delta
        dogdns
        du-dust
        duf
        fd
        file
        fzf
        gping
        icoutils
        imagemagick
        jq
        p7zip
        kubectl
        lame
        lf
        lsd
        mcfly
        mediainfo
        mp3info
        mp3splt
        nixpkgs-unstable.helix
        nixpkgs-unstable.yazi
        openssl
        parallel
        pciutils
        playerctl
        procs
        rclone
        ripgrep
        rsync
        sd
        smbnetfs
        sops
        sshfs
        starship
        tmux
        trash-cli
        tree
        unrar
        usbutils
        zellij
        zoxide
        vault-medusa
      ];
    };
  };
}
