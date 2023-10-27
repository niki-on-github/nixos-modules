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
    environment = {
      systemPackages = with pkgs; [
        bat
        choose
        curlie
        delta
        dogdns
        du-dust
        duf
        fd
        pciutils
        usbutils
        file
        fzf
        gping
        rsync
        parallel
        rclone
        helix
        icoutils
        imagemagick
        jq
        lame
        lf
        lsd
        mcfly
        mp3info
        mp3splt
        nixpkgs-unstable.yazi
        coreutils-full
        playerctl
        procs
        trash-cli
        ripgrep
        sd
        smbnetfs
        sshfs
        tmux
        zoxide
        zellij
      ];
    };
  };
}
