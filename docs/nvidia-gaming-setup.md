# NVIDIA Gaming Configuration for NixOS Laptop

## 🎮 Overview

Your NixOS laptop is now configured with **NVIDIA Optimus** (hybrid graphics) for optimal gaming performance. This setup allows:

- **Intel GPU**: Powers the desktop and basic applications (saves battery)
- **NVIDIA GPU**: Handles demanding games and applications (maximum performance)
- **Steam**: Can automatically or manually use the NVIDIA GPU for gaming

## 🔧 What Was Configured

### Hardware Configuration

- ✅ **NVIDIA Optimus** enabled with proper power management
- ✅ **Hybrid graphics** setup (Intel + NVIDIA)
- ✅ **PRIME offloading** for selective GPU usage
- ✅ **32-bit compatibility** for older games
- ✅ **Vulkan and OpenGL** acceleration on both GPUs

### Gaming Optimizations

- ✅ **Steam** with NVIDIA offloading support
- ✅ **GameMode** for automatic performance optimizations
- ✅ **MangoHud** for FPS and performance monitoring
- ✅ **CoreCtrl** for GPU monitoring and control
- ✅ **DXVK** and **Wine** for Windows game compatibility
- ✅ **Lutris**, **Heroic**, and **Bottles** game launchers

### Environment Variables

- ✅ **NVIDIA offloading** variables set automatically
- ✅ **Gaming-specific** optimizations enabled
- ✅ **Steam runtime** optimized for performance
- ✅ **Vulkan and OpenGL** shader caching enabled

## 🚀 How to Use

### Steam Gaming (Recommended)

#### Option 1: Manual NVIDIA Offloading

```bash
# Launch Steam with NVIDIA GPU
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia steam
```

#### Option 2: Regular Steam (will auto-detect when needed)

```bash
steam
```

Steam should automatically use the NVIDIA GPU for demanding games.

### Manual GPU Offloading

For any application that needs NVIDIA GPU acceleration:

```bash
# Run any game with NVIDIA GPU
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia lutris
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia <your-game-executable>

# Test GPU functionality
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxgears    # OpenGL test
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia vulkaninfo # Vulkan information

# You can also create a simple wrapper function in your shell:
nvidia-run() { __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia "$@"; }
```

### Gaming Launchers

All these launchers are available and NVIDIA-compatible:

```bash
# Through NVIDIA offloading (recommended for best performance)
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia lutris     # Lutris (comprehensive game launcher)
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia heroic     # Heroic (Epic Games + GOG)
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia bottles    # Bottles (Wine prefix manager)

# Or run normally (may auto-detect GPU when needed)
lutris
heroic
bottles
```

## 📊 Monitoring and Troubleshooting

### Check GPU Status

```bash
# NVIDIA GPU information
nvidia-smi

# Vulkan devices (should show both Intel and NVIDIA)
vulkaninfo --summary

# OpenGL information
glxinfo | grep -E "(vendor|renderer)"

# List all GPUs
lspci | grep -E "(VGA|3D)"
```

### Performance Monitoring

- **MangoHud**: Overlay showing FPS, GPU usage, temperatures
- **CoreCtrl**: GUI for GPU monitoring and fan curves
- **nvidia-smi**: Command-line NVIDIA GPU monitoring

### Gaming Performance Tips

1. **For maximum performance**: Use `__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia` to force NVIDIA GPU
2. **For battery saving**: Let the system auto-decide (Intel for desktop, NVIDIA for games)
3. **Steam games**: Should automatically use NVIDIA when needed
4. **Wine/Proton games**: May need manual NVIDIA offloading

## 🔍 Troubleshooting

### Common Issues

#### Steam not using NVIDIA GPU

```bash
# Force Steam to use NVIDIA GPU
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia steam
```

#### Game running slowly

```bash
# Verify game is using NVIDIA GPU
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia <game-command>

# Check GPU usage while playing
nvidia-smi -l 1  # Updates every second
```

#### Check if NVIDIA driver loaded

```bash
lsmod | grep nvidia
# Should show: nvidia, nvidia_modeset, nvidia_uvm, nvidia_drm
```

#### Verify Optimus setup

```bash
# Check PRIME configuration
cat /sys/class/drm/card*/device/enable
# Intel should be 1, NVIDIA should be 0 (powers on when needed)
```

### Bus ID Configuration

The current configuration assumes:

- **Intel GPU**: `PCI:0:2:0`
- **NVIDIA GPU**: `PCI:1:0:0`

If these don't match your hardware, run:

```bash
sudo lshw -c display
```

Look for the PCI bus addresses and update them in `/home/notroot/NixOS/hosts/laptop/configuration.nix`:

```nix
hardware.nvidia.prime = {
  intelBusId = "PCI:X:Y:Z";    # Your Intel GPU bus ID
  nvidiaBusId = "PCI:A:B:C";   # Your NVIDIA GPU bus ID
};
```

## ⚡ Ready to Game!

Your system is now optimized for gaming with:

1. **Automatic GPU switching** for optimal performance/battery balance
2. **Manual GPU control** when you need maximum performance
3. **All major gaming platforms** supported (Steam, Epic, GOG, etc.)
4. **Windows game compatibility** through Wine/Proton
5. **Performance monitoring** tools for optimization

To apply these changes to your system:

```bash
./user-scripts/nixswitch
```

After rebuilding, reboot your system to ensure all NVIDIA drivers are properly loaded, then enjoy gaming with your NVIDIA GPU! 🎮
