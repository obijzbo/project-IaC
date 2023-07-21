#!/bin/bash

sudo su

# Set the username and password
username="devops"
password="123"

# Create the user with a home directory
useradd -m -s /bin/bash "$username"

# Set the password for the user
echo -e "$password\n$password" | passwd "$username"

# Add the user to the wheel group for admin privileges
usermod -aG wheel "$username"

# Copy necessary files and overwrite their contents
cp /vagrant_data/hosts /etc/hosts
cp /vagrant_data/hostname /etc/hostname
cp /vagrant_data/network /etc/sysconfig/network
cp /vagrant_data/config /etc/selinux/config

# Stop and disable firewalld
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo systemctl status firewalld

sudo hostnamectl set-hostname master
sudo hostnamectl set-hostname $(cat /etc/hostname)
sudo systemctl restart network

su - $username

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
containerd config default > /etc/containerd/config.toml
sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.orig
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
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
sudo kubeadm init --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address=192.168.56.20 | tee /vagrant_data/kubeadm-join.sh | grep -oE 'kubeadm join 192\.168\.56\.20:6443 --token [^[:space:]]+ --discovery-token-ca-cert-hash [^[:space:]]+' > /vagrant_data/kubeadm-join.sh
sudo tail -n 2 /vagrant_data/kubeadm-join.sh > /vagrant_data/join.sh
sudo rm kubeadm-join.sh

# Configure kubectl for the current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico networking
sudo yum install -y wget
wget https://raw.githubusercontent.com/projectcalico/calico/master/manifests/calico.yaml
sudo kubectl apply -f calico.yaml
sudo kubectl get pods --all-namespaces
cat /vagrant_data/join.sh
sleep 240
sudo kubectl get nodes -o wide

reboot
