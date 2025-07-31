#!/usr/bin/env bash
# ~/NixOS/scripts/rebuild-default-host.sh
# Rebuild script for default host with new optimizations

set -euo pipefail

echo "🔧 Rebuilding NixOS with new memory and graphics optimizations..."
echo "📋 Changes applied:"
echo "  ✅ Fixed MESA_GLSL_CACHE_MAX_SIZE deprecation"
echo "  ✅ Added extreme-memory VRAM profile for AMD GPU"
echo "  ✅ Forced X11 to fix Wayland/GLFW conflicts"
echo "  ✅ Created host-specific desktop configuration"
echo "  ✅ Added aggressive memory management"
echo "  ✅ Added comprehensive memory monitoring tools"
echo ""

# Check if we're on the default host
hostname=$(hostname)
if [[ "$hostname" != "default" && "$hostname" != "nixos" ]]; then
    echo "⚠️  Warning: This script is intended for the default host"
    echo "   Current hostname: $hostname"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create swap file if it doesn't exist
if [[ ! -f /var/lib/swapfile ]]; then
    echo "📁 Creating swap file..."
    sudo mkdir -p /var/lib
    sudo fallocate -l 8G /var/lib/swapfile || sudo dd if=/dev/zero of=/var/lib/swapfile bs=1M count=8192
    sudo chmod 600 /var/lib/swapfile
    sudo mkswap /var/lib/swapfile
    echo "✅ Swap file created"
fi

# Run the rebuild
echo "🚀 Starting NixOS rebuild..."
echo "   This may take several minutes..."

# Check for syntax errors first
echo "🔍 Checking configuration syntax..."
sudo nixos-rebuild dry-build --flake .#default

# If dry-build succeeds, do the actual rebuild
echo "🏗️  Building and switching to new configuration..."
sudo nixos-rebuild switch --flake .#default

echo ""
echo "🎉 Rebuild completed successfully!"
echo ""
echo "📊 Recommended next steps:"
echo "  1. Reboot to ensure all kernel parameters take effect"
echo "  2. Monitor memory usage with: htop, btop, or smem"
echo "  3. Check GNOME is using X11: echo \$XDG_SESSION_TYPE"
echo "  4. Test applications that were failing (cursor, kitty)"
echo "  5. Monitor GPU with: radeontop or amdgpu_top"
echo ""
echo "🔧 Memory monitoring commands:"
echo "  • smem -t -k                    # Memory by process"
echo "  • cat /proc/meminfo            # Detailed memory info"
echo "  • journalctl -f | grep memory  # Memory pressure logs"
echo "  • sudo swapon --show           # Swap status"
echo ""
echo "⚡ GPU monitoring commands:"
echo "  • radeontop                    # AMD GPU usage"
echo "  • amdgpu_top                   # Advanced AMD monitoring"
echo "  • glxinfo | grep OpenGL       # OpenGL info"
echo "  • vulkaninfo                   # Vulkan support"
echo "" 