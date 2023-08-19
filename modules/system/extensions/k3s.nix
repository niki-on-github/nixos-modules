{ lib, config, pkgs, ... }:
{
  config = {

    environment = {
      systemPackages = with pkgs; [
        age
        fluxcd
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

    networking.firewall.allowedTCPPorts = [ 445 6443 10250 ];

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
  };
}
