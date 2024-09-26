#!/bin/bash

# Redirect all output (stdout and stderr) to a log file
exec > /var/log/k8_script.log 2>&1

# Indicate start
echo "Script execution started"

# Update and upgrade the system
sudo apt update -y && sudo apt upgrade -y

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load necessary kernel modules
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set up required sysctl parameters
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# Install necessary packages
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# Add Docker's official GPG key and repository
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update package index and install containerd
sudo apt update -y
sudo apt install -y containerd.io

# Configure containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart and enable containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Add Kubernetes' official GPG key and repository
sudo mkdir -p /etc/apt/keyrings
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Update package index and install Kubernetes components
sudo apt update -y
sudo apt install -y kubelet kubeadm kubectl

# Hold the Kubernetes packages at their current version
sudo apt-mark hold kubelet kubeadm kubectl

# Pull Kubernetes images
sudo kubeadm config images pull

# Initialize the Kubernetes cluster
sudo kubeadm init 

# > /var/log/kubeadm_init.log 2>&1

# Set up kubeconfig for the current user
USER_HOME=$(getent passwd bigboss | cut -d: -f6)
echo "Setting up kubeconfig for user home: $USER_HOME"

# Create .kube directory
mkdir -p $USER_HOME/.kube
if [ $? -ne 0 ]; then
  echo "Failed to create .kube directory"
  exit 1
fi

# Copy admin.conf to .kube directory
sudo cp -i /etc/kubernetes/admin.conf $USER_HOME/.kube/config
if [ $? -ne 0 ]; then
  echo "Failed to copy admin.conf to .kube directory"
  exit 1
fi

# Change ownership of the config file
sudo chown $(id -u bigboss):$(id -g bigboss) $USER_HOME/.kube/config
if [ $? -ne 0 ]; then
  echo "Failed to change ownership of the kubeconfig file"
  exit 1
fi

#install AZ CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#install docker
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
# Add Docker's official GPG key:
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Indicate completion
echo "Script execution completed"