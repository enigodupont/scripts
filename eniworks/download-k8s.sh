#!/bin/bash

DOWNLOAD_DIR="/opt/bin"
CNI_VERSION="v1.4.0"
CRICTL_VERSION="v1.29.0"
RELEASE_VERSION="v0.16.4"
RELEASE="v1.28.5" #"$(curl -sSL https://dl.k8s.io/release/stable.txt)"

mkdir -p "$DOWNLOAD_DIR"
mkdir -p /opt/cni/bin

echo "--------------------Download CNI--------------------"
curl -sSL "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" | tar -C /opt/cni/bin -xz
echo "--------------------Download crictl--------------------"
curl -sSL "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" | tar -C $DOWNLOAD_DIR -xz
echo "--------------------Download kubelet--------------------"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubelet/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service
echo "--------------------Download kubeadm--------------------"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

echo "--------------------Download kube-release--------------------"
curl -sSL --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}
 
chmod +x {kubeadm,kubelet,kubectl}
mv {kubeadm,kubelet,kubectl} $DOWNLOAD_DIR/
systemctl daemon-reload

echo "--------------------Run the following for the master nodes--------------------"
echo "export KUBECONFIG=/etc/kubernetes/admin.conf"
echo "sudo kubeadm upgrade plan"
echo "sudo kubeadm upgrade apply $RELEASE"
echo "sudo systemctl restart kubelet"
echo "sudo systemctl status kubelet"
echo ""
echo "--------------------Run the following for the workers--------------------"
echo "export KUBECONFIG=/etc/kubernetes/kubelet.conf"
echo "sudo kubeadm upgrade node"
echo "sudo systemctl restart kubelet"
echo "sudo systemctl status kubelet"
echo ""
echo "--------------------If you run into any kubelet network plugin errors--------------------"
echo "Add the following to /var/lib/kubelet/kubeadm-flags.env"
echo "Double check the pause image"
echo 'KUBELET_KUBEADM_ARGS="--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.7 --volume-plugin-dir=/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"'
echo "sudo systemctl restart kubelet"
echo "sudo systemctl status kubelet"