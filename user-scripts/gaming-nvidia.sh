#!/bin/bash
# Gaming with NVIDIA GPU script
# Usage: ./gaming-nvidia.sh [game-command]

echo "Activating NVIDIA GPU for gaming..."

# Load NVIDIA modules
sudo modprobe nvidia
sudo modprobe nvidia_drm
sudo modprobe nvidia_uvm

# Set environment variables for NVIDIA
export __NV_PRIME_RENDER_OFFLOAD=1
export __VK_LAYER_NV_optimus=NVIDIA_only
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export NVIDIA_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0

# Check if NVIDIA is available
if nvidia-smi > /dev/null 2>&1; then
    echo "NVIDIA GTX 1650 Mobile is ready for gaming!"

    # Launch the provided command or Steam
    if [ $# -eq 0 ]; then
        echo "Launching Steam with NVIDIA GPU..."
        steam
    else
        echo "Launching '$*' with NVIDIA GPU..."
        exec "$@"
    fi
else
    echo "Error: NVIDIA GPU not available"
    exit 1
fi