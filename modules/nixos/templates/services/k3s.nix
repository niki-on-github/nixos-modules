{ lib, config, pkgs, ... }:
let
  cfg = config.templates.services.k3s;
in
{
  options.templates.services.k3s = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Single Node K3S Cluster.";
    };

    coredns = {  
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          If enabled coredns will be installed to k3s cluster
        '';
      };    
    };

    loadbalancer = {  
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          If enabled klipper-lb will be enabled on k3s cluster
        '';
      };    
    };

    network = lib.mkOption {
      type = lib.types.str;
      default = "flannel";
      description = ''
        network backend one of [flannel, cilium]
      '';
    };

    argocd = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          If enabled argocd will be installed to k3s cluster
        '';
      };
    };

    flux = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          If enabled flux will be installed to k3s cluster
        '';
      };
    };

    nfs = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          If enabled a localhost only nfs-server will be enabled on node
        '';
      };
      path = lib.mkOption {
        type = lib.types.str;
        default = "/mnt/nfs";
        description = ''
          Host path for nfs server share
        '';
      };
    };

    minio = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          If enabled minio will be enabled on node
        '';
      };
      credentialsFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          File containing the MINIO_ROOT_USER, default is "minioadmin", and
          MINIO_ROOT_PASSWORD (length >= 8), default is "minioadmin"; in the format of
          an EnvironmentFile=, as described by systemd.exec(5). The acess permission must
          be set to 770 for minio:minio.
        '';
      };
      region = lib.mkOption {
        type = lib.types.str;
        default = "local";
        description = ''
          The physical location of the server.
        '';
      };
      buckets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["volsync" "postgres"];
        description = ''
          Bucket name.
        '';
      };
      dataDir = lib.mkOption {
        default = [ "/var/lib/minio/data" ];
        type = lib.types.listOf (lib.types.either lib.types.path lib.types.str);
        description = "The list of data directories or nodes for storing the objects.";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    environment = {
      systemPackages = with pkgs; [
        age
        argocd
        cilium-cli
        fluxcd
        git
        go-task
        minio-client        
        jq
        k9s
        krelay
        kubectl
        nfs-utils
        openiscsi
        openssl_3
        sops

        (writeShellScriptBin "nuke-k3s" ''
          if [ "$EUID" -ne 0 ] ; then
            echo "Please run as root"
            exit 1
          fi
          read -r -p 'Nuke k3s?, confirm with yes (y/N): ' choice
          case "$choice" in
            y|Y|yes|Yes) echo "nuke k3s...";;
            *) exit 0;;
          esac
          if command -v flux; then
            flux uninstall -s
          fi
          kubectl delete deployments --all=true -A
          kubectl delete statefulsets --all=true -A  
          kubectl delete ns --all=true -A    
          kubectl get ns | tail -n +2 | cut -d ' ' -f 1 | xargs -I{} kubectl delete pods --all=true --force=true -n {}
          echo "wait until objects are deleted..."
          sleep 30
          systemctl stop k3s
          rm -rf /var/lib/rancher/k3s/
          rm -rf /var/lib/cni/networks/cbr0/
          if [ -d /opt/k3s/data/temp ]; then
            rm -rf /opt/k3s/data/temp/*
          fi
          sync
          echo -e "\n => reboot now to complete k3s cleanup!"
          sleep 3
          reboot
        '')
      ];

      etc = {
        "rancher/k3s/kubelet.config" = {
          mode = "0750";
          text = ''
            apiVersion: kubelet.config.k8s.io/v1beta1
            kind: KubeletConfiguration
            maxPods: 250
          '';
        };
        "rancher/k3s/k3s.service.env" = {
          mode = "0750";
          text = ''
            K3S_KUBECONFIG_MODE="644"
          '';
        };
      };
    };

    systemd.tmpfiles.rules = lib.mkMerge [
      [
        "d /root/.kube 0755 root root -"
        "L /root/.kube/config  - - - - /etc/rancher/k3s/k3s.yaml"
      ]
      (lib.mkIf cfg.nfs.enable [
        "d ${cfg.nfs.path} 0775 root root -"
        "d ${cfg.nfs.path}/pv 0775 root root -"
      ])
    ];

    boot.kernel.sysctl = {
      "fs.inotify.max_user_instances" = 524288;
      "fs.inotify.max_user_watches" = 524288;
    };

    networking.firewall.allowedTCPPorts = lib.mkMerge [
      [ 80 222 443 445 6443 8080 10250 ]
      (lib.mkIf cfg.nfs.enable [ 2049 ])
      (lib.mkIf cfg.minio.enable [ 9000 9001 ])
    ];

    services = {
      prometheus.exporters.node = {
        enable = true;
      };
      openiscsi = {
        enable = true;
        name = "iscsid";
      };
      nfs.server = lib.mkIf cfg.nfs.enable {
        enable = true;
        exports = ''
          ${cfg.nfs.path} ${config.networking.hostName}(rw,fsid=0,async,no_subtree_check,no_auth_nlm,insecure,no_root_squash)        
        '';
      };
      minio = lib.mkIf cfg.minio.enable {
        enable = true;
        region = cfg.minio.region;
        dataDir = cfg.minio.dataDir;
        rootCredentialsFile = cfg.minio.credentialsFile;
      };
      k3s = {
        enable = true; 
        package = pkgs.k3s;
        role = "server";
        environmentFile = "/etc/rancher/k3s/k3s.service.env";
        extraFlags = toString [
          "--disable=traefik,local-storage,metrics-server${lib.strings.optionalString (!cfg.loadbalancer.enable) ",servicelb"}${lib.strings.optionalString (!cfg.coredns.enable) ",coredns"}"
          "--kubelet-arg=config=/etc/rancher/k3s/kubelet.config"
          "--kube-apiserver-arg='enable-admission-plugins=DefaultStorageClass,DefaultTolerationSeconds,LimitRanger,MutatingAdmissionWebhook,NamespaceLifecycle,NodeRestriction,PersistentVolumeClaimResize,Priority,ResourceQuota,ServiceAccount,TaintNodesByCondition,ValidatingAdmissionWebhook'"
          "${lib.strings.optionalString (cfg.network != "flannel") "--flannel-backend=none"}"
          "${lib.strings.optionalString (cfg.network != "flannel") "--disable-network-policy"}"
          "${lib.strings.optionalString (cfg.network == "cilium") "--kubelet-arg=register-with-taints=node.cilium.io/agent-not-ready:NoExecute"}"
        ];
      };
    };

    systemd = {
      services = {
        k3s.after = lib.mkIf cfg.nfs.enable [ "nfs-server.service" ];
        minio-init = lib.mkIf cfg.minio.enable {
          enable = true;
          path = [ pkgs.minio pkgs.minio-client];
          requiredBy = [ "multi-user.target" ];
          after = [ "minio.service" ];
          serviceConfig = {
            Type = "simple";
            User = "minio";
            Group = "minio";
            RuntimeDirectory = "minio-config";
          };
          script = ''
            set -e
            sleep 5
            source ${cfg.minio.credentialsFile}     
            mc --config-dir "$RUNTIME_DIRECTORY" alias set minio http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"
            ${toString (lib.lists.forEach cfg.minio.buckets (bucket: "mc --config-dir $RUNTIME_DIRECTORY mb --ignore-existing minio/${bucket};"))}
          '';
        };
      };
      timers."k3s-argocd-bootstrap" = lib.mkIf cfg.argocd.enable {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2m";
          OnUnitActiveSec = "3m";
          Unit = "k3s-argocd-bootstrap.service";
        };
      };
      timers."k3s-cilium-bootstrap" = lib.mkIf (cfg.network == "cilium") {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2m";
          OnUnitActiveSec = "3m";
          Unit = "k3s-cilium-bootstrap.service";
        };
      };
      timers."k3s-flux2-bootstrap" = lib.mkIf cfg.flux.enable {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2m";
          OnUnitActiveSec = "3m";
          Unit = "k3s-flux2-bootstrap.service";
        };
      };
    };

    systemd.services."k3s-argocd-bootstrap" = lib.mkIf cfg.argocd.enable {
      script = ''
        export PATH="$PATH:${pkgs.git}/bin"
        if ${pkgs.kubectl}/bin/kubectl get CustomResourceDefinition -A | grep -q "argoproj.io" ; then
          exit 0
        fi
        sleep 20
        if ${pkgs.kubectl}/bin/kubectl get CustomResourceDefinition -A | grep -q "argoproj.io" ; then
          exit 0
        fi
        mkdir -p /tmp/k3s-argocd-bootstrap
        cat > /tmp/k3s-argocd-bootstrap/kustomization.yaml << EOL
        apiVersion: kustomize.config.k8s.io/v1beta1
        kind: Kustomization
        namespace: argocd
        resources:
          - https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        EOL
        ${pkgs.kubectl}/bin/kubectl create namespace argocd || true
        ${pkgs.kubectl}/bin/kubectl apply --kustomize /tmp/k3s-argocd-bootstrap
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };

    systemd.services."k3s-cilium-bootstrap" = lib.mkIf (cfg.network == "cilium") {
      script = ''
        export PATH="$PATH:${pkgs.git}/bin"
        if ${pkgs.kubectl}/bin/kubectl get CustomResourceDefinition -A | grep -q "cilium.io" ; then
          exit 0
        fi
        sleep 20
        if ${pkgs.kubectl}/bin/kubectl get CustomResourceDefinition -A | grep -q "cilium.io" ; then
          exit 0
        fi
        ${pkgs.cilium-cli}/bin/cilium install
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };

    systemd.services."k3s-flux2-bootstrap" = lib.mkIf cfg.flux.enable {
      script = ''
        export PATH="$PATH:${pkgs.git}/bin"
        if ${pkgs.kubectl}/bin/kubectl get CustomResourceDefinition -A | grep -q "toolkit.fluxcd.io" ; then
          exit 0
        fi
        sleep 20
        if ${pkgs.kubectl}/bin/kubectl get CustomResourceDefinition -A | grep -q "toolkit.fluxcd.io" ; then
          exit 0
        fi
        mkdir -p /tmp/k3s-flux2-bootstrap
        cat > /tmp/k3s-flux2-bootstrap/kustomization.yaml << EOL
        apiVersion: kustomize.config.k8s.io/v1beta1
        kind: Kustomization
        resources:
          - github.com/fluxcd/flux2/manifests/install
        EOL
        ${pkgs.kubectl}/bin/kubectl apply --kustomize /tmp/k3s-flux2-bootstrap
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };
}
