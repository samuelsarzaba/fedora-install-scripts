#!/bin/bash

# Secure Boot Setup: Repository setup and initial system update
echo "Starting Secure Boot Setup: Repository setup and initial system update..."

# Add RPM Fusion repositories
echo "Adding RPM Fusion repositories..."
sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Full system update
echo "Performing system update..."
sudo dnf upgrade --refresh -y

# Install signing modules
echo "Installing signing modules..."
sudo dnf install -y kmodtool akmods mokutil openssl

# Generate key
echo "Generating key..."
sudo kmodgenca -a

# Import key
echo "Importing key into MOK..."
sudo mokutil --import /etc/pki/akmods/certs/public_key.der

# Final message and reboot
echo "Secure Boot Setup complete. System will reboot in 10 seconds. After reboot, run nvidia_driver_install.sh"
echo "IMPORTANT: During reboot, you will be prompted to enroll the MOK key."
echo "Select 'Enroll MOK' and follow the prompts using the password you set."
echo -e "\nRebooting in:"
for i in {10..1}; do
    echo -ne "\r$i seconds remaining..."
    sleep 1
done
echo -e "\nRebooting now..."
sudo systemctl reboot