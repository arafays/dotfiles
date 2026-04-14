#!/bin/bash

# Add user beera with admin permissions
sudo useradd -m -G wheel beera
sudo passwd beera

# Create shared folder
sudo mkdir -p /home/shared

# Set up permissions for shared folder
# Create a shared group for all users
sudo groupadd -f sharedgroup

# Add current users to the shared group
sudo usermod -aG sharedgroup arafays
sudo usermod -aG sharedgroup beera

# Set ownership and permissions
sudo chown root:sharedgroup /home/shared
sudo chmod 2775 /home/shared

# Set default ACL so new files are accessible to all users
sudo setfacl -R -m u::rwx,g::rwx,o::rwx /home/shared
sudo setfacl -d -m u::rwx,g::rwx,o::rwx /home/shared

echo "Setup complete!"
echo "User 'beera' created with sudo permissions"
echo "Shared folder created at /home/shared"
echo "All users can read, write, and delete any files in /home/shared"
