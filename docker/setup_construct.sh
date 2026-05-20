#!/bin/bash

set -e  # exit on any error

echo "🔧 Removing old ROS sources..."
sudo rm -f /etc/apt/sources.list.d/ros*.list

echo "🔧 Creating keyrings directory..."
sudo mkdir -p /usr/share/keyrings

echo "🔧 Adding ROS key..."
curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
  | sudo tee /usr/share/keyrings/ros-archive-keyring.gpg > /dev/null

echo "🔧 Adding ROS2 repository..."
echo "deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu focal main" \
  | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# echo "🔧 Adding fallback mirror..."
# sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
# sudo sed 's|http://archive.ubuntu.com/ubuntu|http://mirror.kakao.com/ubuntu|g' \
#   /etc/apt/sources.list.backup | sudo tee -a /etc/apt/sources.list > /dev/null
echo "🌍 Switching to automatic mirror selection..."
sudo sed -i 's|http://archive.ubuntu.com/ubuntu|mirror://mirrors.ubuntu.com/mirrors.txt|g' /etc/apt/sources.list
sudo sed -i 's|http://security.ubuntu.com/ubuntu|mirror://mirrors.ubuntu.com/mirrors.txt|g' /etc/apt/sources.list

echo "🔄 Updating package lists..."
sudo apt-get update

echo "🇽𝟏𝟏 Installing Docker..."
sudo apt --fix-broken install
sudo apt install x11-xserver-utils

echo "🐳 Installing Docker..."
sudo apt-get install -y docker.io docker-compose

echo "🚀 Starting Docker service..."
sudo service docker start
xhost +local:docker

echo "👤 Adding user to docker group..."
sudo usermod -aG docker $USER


echo "⚠️ Applying docker group changes..."
# exec sg docker newgrp `id -gn`
echo 'if ! id -nG | grep -qw docker; then exec newgrp docker; fi' >> ~/.bashrc


echo "🐳 Setting DOCKERHUB_USER as `tesarect` in ~/.bashrc..."
grep -qxF 'export DOCKERHUB_USER="tesarect"' ~/.bashrc \
  || echo 'export DOCKERHUB_USER="tesarect"' >> ~/.bashrc

echo "✅ Setup complete!"