#!/bin/bash

# Quick fix for Ubuntu PPA repository issues
# Run this if you encounter PPA errors during deployment

set -e

echo "🔧 Fixing Ubuntu PPA repository issues..."

# Get Ubuntu version
UBUNTU_VERSION=$(lsb_release -cs)
echo "📋 Ubuntu version: $UBUNTU_VERSION"

# Remove problematic PPA if it exists
if grep -q "deadsnakes/ppa" /etc/apt/sources.list.d/*; then
    echo "🗑️ Removing problematic deadsnakes PPA..."
    add-apt-repository --remove ppa:deadsnakes/ppa -y
fi

# Update package lists
echo "📦 Updating package lists..."
apt-get update

# Install Python 3.10 as fallback (available on most Ubuntu versions)
echo "🐍 Installing Python 3.10..."
apt-get install -y python3.10 python3.10-pip python3.10-venv python3.10-dev

# Create symlinks for python3.11
echo "🔗 Creating Python 3.11 symlinks..."
ln -sf /usr/bin/python3.10 /usr/bin/python3.11
ln -sf /usr/bin/pip3.10 /usr/bin/pip3.11

# Verify installation
echo "✅ Verifying Python installation..."
python3.11 --version
pip3.11 --version

echo "🎉 PPA fix completed! You can now continue with the deployment."
echo "💡 Run: sudo ./deploy-ubuntu-vps.sh" 