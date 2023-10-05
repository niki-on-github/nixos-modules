{ lib, config, pkgs, ... }:
{
  options = {
    services.k3s-argocd-bootstrap = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          If enabled argocd will be installed to k3s cluster
        '';
      };
    };
    services.k3s-flux-bootstrap = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          If enabled fluxcd will be installed to k3s cluster
        '';
      };
    };
  };

  config = {

    environment = {
      systemPackages = with pkgs; [
        age
        argocd
        fluxcd
        git
        go-task
        k9s
        kubectl
        nfs-utils
        openiscsi
        openssl_3
        sops
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

    systemd.tmpfiles.rules = [
      "d /root/.kube 0755 root root -"
      "L /root/.kube/config  - - - - /etc/rancher/k3s/k3s.yaml"
    ];

    boot.kernel.sysctl = {
      "fs.inotify.max_user_instances" = 524288;
      "fs.inotify.max_user_watches" = 524288;
    };

    virtualisation.docker.enable = true;

    networking.firewall.allowedTCPPorts = [ 80 443 445 6443 8080 10250 ];

    services.openiscsi = {
      enable = true;
      name = "iscsid";
    };

    services.prometheus.exporters.node = {
      enable = true;
    };

    services.k3s = {
      enable = true;
      package = pkgs.k3s;
      role = "server";
      environmentFile = "/etc/rancher/k3s/k3s.service.env";
      extraFlags = toString [
        "--disable=traefik,local-storage,metrics-server"
        "--kubelet-arg=config=/etc/rancher/k3s/kubelet.config"
        "--kube-apiserver-arg='enable-admission-plugins=DefaultStorageClass,DefaultTolerationSeconds,LimitRanger,MutatingAdmissionWebhook,NamespaceLifecycle,NodeRestriction,PersistentVolumeClaimResize,Priority,ResourceQuota,ServiceAccount,TaintNodesByCondition,ValidatingAdmissionWebhook'"
      ];
    };

    systemd.timers."k3s-argocd-bootstrap" = lib.mkIf config.services.k3s-argocd-bootstrap.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "3m";
        OnUnitActiveSec = "5m";
        Unit = "k3s-argocd-bootstrap.service";
      };
    };

    systemd.services."k3s-argocd-bootstrap" = lib.mkIf config.services.k3s-argocd-bootstrap.enable {
      script = ''
        export PATH="$PATH:${pkgs.git}/bin"
        if ${pkgs.kubectl}/bin/kubectl get CustomResourceDefinition -A | grep -q "argoproj.io" ; then
          exit 0
        fi
        sleep 30
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

    systemd.timers."k3s-flux2-bootstrap" = lib.mkIf config.services.k3s-flux-bootstrap.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "3m";
        OnUnitActiveSec = "5m";
        Unit = "k3s-flux2-bootstrap.service";
      };
    };

    systemd.services."k3s-flux2-bootstrap" = lib.mkIf config.services.k3s-flux-bootstrap.enable {
      script = ''
        export PATH="$PATH:${pkgs.git}/bin"
        if ${pkgs.kubectl}/bin/kubectl get CustomResourceDefinition -A | grep -q "toolkit.fluxcd.io" ; then
          exit 0
        fi
        sleep 30
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
