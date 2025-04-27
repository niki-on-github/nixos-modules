
{ config, lib, pkgs, ... }:

let
  setup = config.templates.system.setup;
  cfg = config.templates.system.unlock;
in
{
  options.templates.system.unlock = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable System Unlock.";
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "vault hostname";
    };
    token = lib.mkOption {
      type = lib.types.str;
      description = "vault token";
    };
    uri = lib.mkOption {
      type = lib.types.str;
      default = "https://vault.k8s.lan/v1/host";
      description = "vault uri";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.hasAttr "encryption" setup && setup.encryption == "system";
        message = "config.templates.system.setup.encryption must be set to 'system' to use the configured system unlock method!";
      }
    ];
    boot.initrd = {
      kernelModules = [ "af_packet" ];
      # use `lspci -v | grep -i ethernet -A 20` to get the reuired kernelModules
      availableKernelModules = [ "e1000e" "r8169" "ixgbe" "igb" "virtio_pci" ];
      network = {
        enable = true;
        udhcpc = {
          enable = true;
          extraArgs = ["-t" "12"]; # Send up to 12 discover packets
        };
        flushBeforeStage2 = true;
      };
      extraUtilsCommands = ''
        copy_bin_and_libs ${pkgs.curl}/bin/curl
        copy_bin_and_libs ${pkgs.iproute2}/bin/ip
        copy_bin_and_libs ${pkgs.jq}/bin/jq
        copy_bin_and_libs ${pkgs.gnused}/bin/sed
      '';
      extraFiles = {
        "/etc/ssl/certs/ca-certificates.crt".source = pkgs.writeText "ca-certificates.crt" ''
          ${builtins.concatStringsSep "\n" (map (cert: builtins.readFile cert) config.security.pki.certificateFiles)}
          ${builtins.readFile "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"}
        '';
      };
      luks.devices.system = {
        preOpenCommands = ''
          ip a
          echo "Try fetch system unlock key via https..."
          curl -H "X-Vault-Token: ${cfg.token}" "${cfg.uri}/${cfg.hostname}" | jq '.data.ssh_host_ed25519_key' | sed 's/"//g' | sed 's/\\n/\n/g' > /disk.key
        '';
        fallbackToPassword = true;
        keyFile = "/disk.key";
      };
    };
  };
}
