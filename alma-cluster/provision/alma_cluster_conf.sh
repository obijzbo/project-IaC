#!/bin/bash

# Copy necessary files and overwrite their contents
sudo cat /vagrant_data/hosts > /etc/hosts
sudo cat /vagrant_data/hostname > /etc/hostname
sudo cat /vagrant_data/network > /etc/sysconfig/network
sudo cat /vagrant_data/config > /etc/selinux/config

# Restart network-related services
sudo systemctl restart network
sudo systemctl restart network-scripts
sudo systemctl restart networking

# Stop and disable firewalld
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo systemctl status firewalld

# Load kernel modules
sudo sh -c 'cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF'

# Configure network settings
sudo sh -c 'cat <<EOF >> /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF'

sudo sysctl --system

# Disable swap
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
free -m

# Install necessary packages
sudo dnf install -y dnf-utils
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf makecache
sudo dnf install -y containerd.io
sudo mv /etc/containerd/config.toml /etc/containerd/config.toml.orig
sudo cp /vagrant_data/config.toml /etc/containerd/config.toml
sudo systemctl enable --now containerd
sudo systemctl is-enabled containerd
sudo systemctl status containerd

# Add Kubernetes repository and install Kubernetes components
sudo sh -c 'cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF'

sudo dnf makecache
sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

# Enable required kernel module
sudo modprobe br_netfilter
lsmod | grep br_netfilter

# Pull Kubernetes container images
sudo kubeadm config images pull

# Initialize Kubernetes cluster
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo kubeadm init --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address=192.168.56.20

# Configure kubectl for the current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf

# Install Calico networking
sudo yum install -y wget
wget https://raw.githubusercontent.com/projectcalico/calico/master/manifests/calico.yaml
kubectl apply -f calico.yaml
kubectl get pods --all-namespaces
kubectl get nodes -o wide

# Generate and store worker join command
sudo kubeadm token create --print-join-command > /vagrant_data/join-worker.sh
