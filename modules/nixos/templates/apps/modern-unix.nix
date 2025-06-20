{ lib, config, pkgs, nixpkgs-unstable, ... }:

let
  cfg = config.templates.apps.modern-unix;
in
{
  options.templates.apps.modern-unix = {
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
        lftp
        wget
        inetutils
        gping
        icoutils
        jq
        ncdu
        restic
        p7zip
        kubectl
        lf
        lsd
        mcfly
        mediainfo
        nixpkgs-unstable.helix
        nixpkgs-unstable.yazi
        openssl
        parallel
        pciutils
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
        unzip
        usbutils
        zellij
        zoxide
        vault-medusa
        zip
      ];
    };
  };
}
