sudo cp /vagrant_data/hosts /etc/hosts
sudo cp /vagrant_data/hostname /etc/hostname
sudo cp /vagrant_data/network /etc/sysconfig/network
sudo cp /vagrant_data/config /etc/selinux/config
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo systemctl status firewalld
sudo su
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
cat <<EOF |
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a
free -m
dnf install dnf-utils
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf repolist
dnf makecache
dnf install containerd.io -y
mv /etc/containerd/config.toml /etc/containerd/config.toml.orig
cp /vagrant_data/config.toml /etc/containerd/config.toml
systemctl enable --now containerd
systemctl is-enabled containerd
systemctl status containerd
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
dnf repolist
dnf makecache
dnf install kubelet kubeadm kubectl --disableexcludes=kubernetes -y
echo 1 > /proc/sys/net/ipv4/ip_forward
reboot
