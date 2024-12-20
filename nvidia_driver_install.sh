#!/bin/bash

# NVIDIA Driver Installation
echo "Starting NVIDIA driver installation..."

# Configuration options
echo -e "\nSetup Options:"

# CUDA support choice
while true; do
    read -p "Do you want to install CUDA support? (y/n): " cuda_choice
    case $cuda_choice in
        [Yy]* ) install_cuda=true; break;;
        [Nn]* ) install_cuda=false; break;;
        * ) echo "Please answer y or n.";;
    esac
done

# GSP firmware choice
while true; do
    read -p "Do you want to disable GSP firmware? (y/n): " gsp_choice
    case $gsp_choice in
        [Yy]* ) disable_gsp=true; break;;
        [Nn]* ) disable_gsp=false; break;;
        * ) echo "Please answer y or n.";;
    esac
done

echo -e "\nProceeding with installation...\n"

# Install NVIDIA drivers
echo "Installing NVIDIA drivers..."
sudo dnf install -y gcc kernel-headers kernel-devel akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-libs xorg-x11-drv-nvidia-libs.i686

# Install CUDA support if selected
if [ "$install_cuda" = true ]; then
    echo "Installing CUDA support..."
    sudo dnf install -y xorg-x11-drv-nvidia-cuda
else
    echo "Skipping CUDA installation..."
fi

echo "Waiting for modules to build..."
# Function to check nvidia module build status
check_nvidia_module() {
    if modinfo -F version nvidia > /dev/null 2>&1; then
        echo "NVIDIA modules built successfully!"
        return 0
    else
        return 1
    fi
}

# Wait for modules to build with timeout
TIMEOUT=600  # 10 minutes timeout
INTERVAL=30  # Check every 30 seconds
ELAPSED=0

while ! check_nvidia_module; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "Timeout waiting for NVIDIA modules to build. Please check 'dmesg' for errors."
        exit 1
    fi
    echo "Still building... (checking every 30 seconds)"
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

echo "Forcing module rebuild and boot image update..."
sudo akmods --force
sudo dracut --force

# Handle GSP Firmware based on user choice
if [ "$disable_gsp" = true ]; then
    echo "Disabling GSP Firmware..."
    sudo grubby --update-kernel=ALL --args=nvidia.NVreg_EnableGpuFirmware=0
else
    echo "Keeping GSP Firmware enabled..."
fi

# Verify installation
echo "Verifying NVIDIA driver installation..."
if nvidia-smi > /dev/null 2>&1; then
    echo "NVIDIA drivers installed and working correctly!"
else
    echo "WARNING: NVIDIA drivers might not be loaded properly."
    echo "Please check 'dmesg' and '/var/log/akmods' for any errors."
fi

echo "NVIDIA setup complete! A final reboot is recommended."

while true; do
    read -p "Would you like to reboot now? (y/n): " reboot_choice
    case $reboot_choice in
        [Yy]* ) sudo systemctl reboot; break;;
        [Nn]* ) break;;
        * ) echo "Please answer y or n.";;
    esac
done