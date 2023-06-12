#!/bin/bash

install_type=${1:-master}

echo "--------------------Install type $install_type--------------------"

# No Swap
swapoff -a
sed -i '/\/swap.img/ s/^/#/' /etc/fstab

# Install packages
apt-get install -y docker.io socat conntrack nfs-common

# Disable bad net packages
echo "blacklist cdc_mbim" >> /etc/modprobe.d/blacklist.conf
echo "blacklist cdc_ncm" >> /etc/modprobe.d/blacklist.conf
echo "Make sure to restart for full net connectivity, if you aren't using a USB dongle perhaps revert this..."

# Setup Network
echo "--------------------Setup Network--------------------"

systemctl enable docker
modprobe br_netfilter

cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# Download Binaries
echo "--------------------Download Binaries--------------------"
#CNI_VERSION="v0.8.2"
CNI_VERSION="v1.0.1"
CRICTL_VERSION="v1.22.0"
RELEASE_VERSION="v0.12.0"
DOWNLOAD_DIR="/opt/bin"
RELEASE="v1.23.1" #"$(curl -sSL https://dl.k8s.io/release/stable.txt)"

mkdir -p /opt/bin
mkdir -p /opt/cni/bin
mkdir -p /etc/systemd/system/kubelet.service.d

echo "--------------------Download CNI--------------------"
curl -sSL "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" | tar -C /opt/cni/bin -xz
echo "--------------------Download crictl--------------------"
curl -sSL "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" | tar -C $DOWNLOAD_DIR -xz
echo "--------------------Download kubelet--------------------"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service
echo "--------------------Download kubeadm--------------------"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
echo "--------------------Download kube-release--------------------"
curl -sSL --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}

chmod +x {kubeadm,kubelet,kubectl}
mv {kubeadm,kubelet,kubectl} $DOWNLOAD_DIR/

# Link binaries
cd /bin
ln -s $DOWNLOAD_DIR/ .
cd -

systemctl enable --now kubelet 
systemctl status kubelet  --no-pager

if ! [ "$install_type" = "master" ]
then 
	echo "Non-Master Install, exiting now ..."
	echo "Pull worker config from master, and join the cluster"
	echo "kubeadm join --config worker-config.yaml"
	exit
fi

# Setup Master
echo "--------------------Setup Master--------------------"
cat <<EOF | tee kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  kubeletExtraArgs:
    volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
clusterName: eniworks
networking:
  podSubnet: 10.65.0.0/16
controllerManager:
  extraArgs:
    flex-volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
EOF

kubeadm config images pull
kubeadm init --config kubeadm-config.yaml

mkdir -p "$HOME/.kube"
cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"

# Install CNI
echo "--------------------Install calico CNI--------------------"
cat <<EOF | tee calico.yaml
# Source: https://docs.projectcalico.org/manifests/custom-resources.yaml
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  calicoNetwork:
    # Note: The ipPools section cannot be modified post-install.
    ipPools:
    - blockSize: 26
      cidr: 10.65.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
  flexVolumePath: /opt/libexec/kubernetes/kubelet-plugins/volume/exec/

---

# This section configures the Calico API server.
# For more information, see: https://docs.projectcalico.org/v3.21/reference/installation/api#operator.tigera.io/v1.APIServer
apiVersion: operator.tigera.io/v1
kind: APIServer 
metadata: 
  name: default 
spec: {}
EOF

kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl apply -f calico.yaml
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl get pods -A
kubectl get nodes -o wide

# Generate Worker Config
echo "--------------------Generate Worker Config--------------------"
URL=$(kubectl config view -ojsonpath='{.clusters[0].cluster.server}')
prefix="https://"
short_url=${URL#"$prefix"}

cat <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: $short_url
    token: $(kubeadm token create)
    caCertHashes:
    - sha256:$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
controlPlane:
nodeRegistration:
  kubeletExtraArgs:
    volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
EOF

