#!/bin/bash

sudo su
# Copy necessary files and overwrite their contents
sudo cat /vagrant_data/hosts > /etc/hosts
sudo cat /vagrant_data/hostname > /etc/hostname
sudo cat /vagrant_data/network > /etc/sysconfig/network
sudo cat /vagrant_data/config > /etc/selinux/config

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

reboot
