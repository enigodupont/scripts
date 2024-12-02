#!/bin/bash

install_type=${1:-master}

echo "--------------------Install type $install_type--------------------"

# No Swap
swapoff -a
sed -i '/\/swap.img/ s/^/#/' /etc/fstab

# Install packages
apt-get install -y jq socat conntrack nfs-common ebtables ethtool apt-transport-https ca-certificates curl gnupg containerd inxi net-tools
# Disable bad net packages
echo "blacklist cdc_mbim" >> /etc/modprobe.d/blacklist.conf
echo "blacklist cdc_ncm" >> /etc/modprobe.d/blacklist.conf
echo "Make sure to create /etc/udev/rules.d/50-usb-realtek-net.rules if you are using a realtek usb" 
echo "Make sure to restart for full net connectivity, if you aren't using a USB dongle perhaps revert this..."

# Setup Network
echo "--------------------Setup Network--------------------"

systemctl enable containerd
apt remove --assume-yes --purge apparmor
modprobe br_netfilter

cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

# Download Binaries
echo "--------------------Download Binaries--------------------"
CNI_VERSION="v1.4.0"
CRICTL_VERSION="v1.29.0"
RELEASE_VERSION="v0.16.4"
DOWNLOAD_DIR="/opt/bin"
RELEASE="v1.28.5" #"$(curl -sSL https://dl.k8s.io/release/stable.txt)"

mkdir -p /opt/bin
mkdir -p /opt/cni/bin
mkdir -p /etc/systemd/system/kubelet.service.d
mkdir -p /etc/kubernetes/manifests
mkdir -p /etc/containerd

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

# Link binaries
cd /bin
ln -s $DOWNLOAD_DIR/* .
cd -

systemctl enable --now kubelet 
systemctl status kubelet  --no-pager

containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl restart containerd
systemctl restart kubelet

if ! [ "$install_type" = "master" ]
then 

	echo "Non-Master Install, exiting now ..."
	echo "Pull worker config from master, and join the cluster"
	echo "kubeadm join --config worker-config.yaml"
  echo "Make sure to reboot and add the network rules for realtek usb ethernet"
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

# TODO, IF WE HAVE TO RECREATE THE MASTER WE WILL NEED TO UPDATE THIS SECTION
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

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
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
apiVersion: kubeadm.k8s.io/v1beta3
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

systemctl restart kubelet
