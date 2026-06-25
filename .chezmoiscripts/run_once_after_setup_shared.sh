#!/bin/bash
set -euo pipefail

# idempotent: create user beera with sudo permissions
if id "beera" &>/dev/null; then
  echo "User beera already exists, skipping creation."
else
  sudo useradd -m -G wheel beera
  echo "beera:changeme" | sudo chpasswd
  echo "User beera created. Temporary password is 'changeme' — please change immediately with: passwd"
fi

# Create shared folder
sudo mkdir -p /home/shared

# Set up permissions for shared folder
sudo groupadd -f sharedgroup

# Add current users to the shared group
sudo usermod -aG sharedgroup arafays 2>/dev/null || true
sudo usermod -aG sharedgroup beera 2>/dev/null || true

# Set ownership and permissions
sudo chown root:sharedgroup /home/shared
sudo chmod 2775 /home/shared

# World-accessible ACL so anyone can use the shared folder
sudo setfacl -R -m u::rwx,g::rwx,o::rwx /home/shared
sudo setfacl -d -m u::rwx,g::rwx,o::rwx /home/shared

# Add a Shared shortcut in /etc/skel so new users automatically get it
sudo mkdir -p /etc/skel
if [ ! -L /etc/skel/Shared ]; then
  sudo ln -sf /home/shared /etc/skel/Shared
  echo "Created /etc/skel/Shared -> /home/shared symlink for new users."
fi

echo ""
echo "Setup complete!"
echo "User 'beera' created with sudo permissions"
echo "Shared folder created at /home/shared"
echo "All users can read, write, and delete any files in /home/shared"
echo "New users will automatically have a ~/Shared shortcut in their home."
