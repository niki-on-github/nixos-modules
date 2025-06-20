{ config, lib, pkgs, ... }:

let
  secrets = import ./../../../../secrets/secrets.nix;
  cfg = config.templates.backup.hetzner;
  snapshot-prefix = "@borgbackup-";
  snapshot-dest-path = if config.templates.backup.hetzner.snapshot.path == "/"
    then "/${snapshot-prefix}${config.templates.backup.hetzner.name}"
    else "${config.templates.backup.hetzner.snapshot.path}/${snapshot-prefix}${config.templates.backup.hetzner.name}";
  paths = if (cfg.snapshot.inplace || !cfg.snapshot.enable) then
    cfg.paths
  else
    map (str:
    if cfg.snapshot.path == "/" then
      snapshot-dest-path + "/" + lib.strings.removePrefix cfg.snapshot.path str
    else if lib.strings.hasPrefix cfg.snapshot.path str then
      snapshot-dest-path + lib.strings.removePrefix cfg.snapshot.path str
    else
      str
  ) cfg.paths;
in
{
  options.templates.backup.hetzner = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable hetzner backup";
    };
    snapshot = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Create an atomic temporary read-only btrfs snapshot before the backup starts and use the snapshot as backup source";
      };
      inplace = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Mount snapshot inplace to use the original paths for the backup. This does not work for the system root partition `/`";
      };
      path = lib.mkOption {
        type = lib.types.str;
        description = "Paths to backup";
      };
    };
    password-path = lib.mkOption {
      type = lib.types.str;
      description = "Path to password secret file";
    };
    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Backup Paths";
    };
    name = lib.mkOption {
      type = lib.types.str;
      default = "hetzner";
      description = "Borg backup job name";
    };
    schedule = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "Schedule Expression";
    };
    ssh-key = lib.mkOption {
      type = lib.types.str;
      default = "/root/.ssh/ssh.hetzner-storagebox";
      description = "Hetzner borg ssh private keyfile path";
    };
    id = lib.mkOption {
      type = lib.types.str;
      default = secrets.hetznerStorageboxId;
      description = "Hetzner storagebox id";
    };
    hostkey = lib.mkOption {
      type = lib.types.str;
      default = secrets.hetznerHostkey;
      description = "Hetzner Storagebox hostkey. Use `ssh-keyscan -p 23 xxx.your-storagebox.de` to get this";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.snapshot.enable || cfg.snapshot.path != "/" || !cfg.snapshot.inplace;
        message = "Remounting inplace for the root partition does not work. Please set config.templates.backup.hetzner.snapshot.inplace = false;";
      }
    ];

    # Manually trigger with `systemctl start borgbackup-job-${cfg.name}`
    services.borgbackup.jobs."${cfg.name}" = {
      paths = paths;
      exclude = lib.mkIf cfg.snapshot.inplace [
        "${snapshot-dest-path}"
      ];
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${cfg.password-path}";
      };
      repo = "ssh://${cfg.id}@${cfg.id}.your-storagebox.de:23/./${config.networking.hostName}";
      compression = "auto,zstd";
      environment = {
        BORG_RSH = "ssh -i ${cfg.ssh-key}";
      };
      startAt = "${cfg.schedule}";
      prune.keep = {
        daily = 4;
        weekly = 3;
        monthly = 2;
      };
      # NOTE We use atomic btrfs read only snapshots to get consistent backups
      # When cfg.snapshot.inplace is set we mount the read only snapshot inplace 
      # Therefore the service has PrivateMounts = true, so the unmount does not affect the system.
      preHook = lib.mkIf cfg.snapshot.enable ''
        set -Eeuxo pipefail

        # first remove the snapshot from previous backup
        if [ -e "${snapshot-dest-path}" ]; then
          btrfs subvolume delete ${snapshot-dest-path}
        fi

        btrfs subvolume snapshot -r ${cfg.snapshot.path} ${snapshot-dest-path}

        ${if cfg.snapshot.inplace then ''
        DEVICE=''$(findmnt -no SOURCE --target "${cfg.snapshot.path}" | sed 's/\[.*\]//')
        SUBVOL=''$(findmnt -no OPTIONS --target "${cfg.snapshot.path}" | grep -o 'subvol=[^,]*' | cut -d= -f2)
        [[ "''$SUBVOL" != /* ]] && SUBVOL="/''$SUBVOL"

        umount ${cfg.snapshot.path}
        mount -t btrfs -o subvol=''${SUBVOL}/${snapshot-prefix}${cfg.name} ''$DEVICE ${cfg.snapshot.path}
        '' else ""}
      '';
    };
    
    systemd.services.borgbackup-job-hetzner = {
      path = with pkgs; [btrfs-progs umount mount util-linux];
      serviceConfig = {
        PrivateMounts = true;
        ProtectSystem = lib.mkIf (cfg.snapshot.path == "/") (lib.mkForce "full");
        ReadWritePaths = [ "${cfg.snapshot.path}" ];
      };
    };

    services.openssh = {
      enable = true;
      knownHosts = {
        "hetzner" = {
          hostNames = [ "[${cfg.id}.your-storagebox.de]:23" ];
          publicKey = "${cfg.hostkey}"; # use `ssh-keyscan -p 23 xxx.your-storagebox.de` to get this
        };
      };
    };

    environment = {
      variables = {
        # Set environment variables for borg so we can access backups on the cli
        BORG_PASSCOMMAND = "${config.services.borgbackup.jobs.${cfg.name}.encryption.passCommand}";
        BORG_REPO = "${config.services.borgbackup.jobs.${cfg.name}.repo}";
        BORG_RSH = "${config.services.borgbackup.jobs.${cfg.name}.environment.BORG_RSH}";
      };
      systemPackages = [
        pkgs.borgbackup
      ];
    };
  };
}
