# Laptop Configuration

This directory contains the laptop-specific NixOS configuration that is **independent** from the shared desktop configuration to avoid Wayland compatibility issues.

## Key Differences from Desktop

### 🚫 What's NOT Used
- **Shared module** (`../shared/common.nix`) - Removed to avoid GNOME/Wayland conflicts
- **GNOME overlays** - No gnome-session modifications that can cause display issues
- **Gaming packages** - Disabled to save battery and storage space
- **Heavy media packages** - Audio/video editing tools disabled
- **Aggressive Wayland settings** - No forced Wayland environment variables

### ✅ What's Included
- **Pure X11 session** - Forces `gnome-xorg` for maximum stability
- **Laptop essentials** - `powertop`, `acpi`, `brightnessctl`
- **Basic GNOME** - Core desktop environment without heavy customizations
- **Power management** - Lid switch behavior, battery management
- **Minimal packages** - Browsers, development tools, utilities only

## Environment Variables

The laptop configuration explicitly forces X11 backends:

```bash
XDG_SESSION_TYPE=x11
WAYLAND_DISPLAY=""
QT_QPA_PLATFORM=xcb
GDK_BACKEND=x11
SDL_VIDEODRIVER=x11
MOZ_ENABLE_WAYLAND=0
NIXOS_OZONE_WL=0
```

## Laptop-Specific Features

- **Auto-login** enabled for convenience
- **Touchpad support** with natural scrolling
- **Power profiles daemon** for battery optimization
- **Lid switch behavior**: suspend when closed, lock when on external power
- **Bluetooth support** enabled
- **Printing support** disabled to reduce complexity

## Building and Switching

```bash
# Build configuration
nixos-rebuild build --flake .#laptop

# Test configuration (temporary)
sudo nixos-rebuild test --flake .#laptop

# Apply configuration permanently
sudo nixos-rebuild switch --flake .#laptop
```

## Troubleshooting

If you encounter display issues:

1. **Check session type**: `echo $XDG_SESSION_TYPE` should return `x11`
2. **Verify GNOME session**: Should be using `gnome-xorg` not `gnome`
3. **Check environment**: `env | grep WAYLAND` should show empty WAYLAND_DISPLAY

## Re-enabling Shared Features

If you want to re-enable features from the shared module:

1. **Add specific modules** instead of importing `../shared/common.nix`
2. **Test carefully** - some shared settings may conflict with laptop hardware
3. **Keep X11 enforcement** - don't remove the `lib.mkForce` directives for display variables

## GNOME Extensions

The laptop comes with a comprehensive set of GNOME extensions for productivity and customization:

### 🎯 Core Extensions (Your Requests)
- **Caffeine** - Prevent sleep/screen lock when needed
- **Vitals** - System monitoring (CPU, temperature, memory, network)
- **Forge** - Tiling window manager for better window organization
- **Arc Menu** - Application menu replacement (brings back classic menu)
- **Fuzzy App Search** - Better application search functionality
- **Launch New Instance** - Always launch new app instances instead of focusing existing
- **Auto Move Windows** - Remember window positions per workspace
- **Clipboard Indicator** - Clipboard history manager

### 🐱 Fun Extensions
- **RunCat** - The running cat in top bar that shows CPU usage by running speed!

### 🛠️ Productivity Extensions
- **Dash to Dock** - Enhanced dock with better customization
- **GSConnect** - Phone integration (KDE Connect for GNOME)
- **Workspace Indicator** - Better workspace management
- **Sound Output Device Chooser** - Quick audio device switching
- **Removable Drive Menu** - USB drive management
- **Places Status Indicator** - Quick access to bookmarks
- **Night Theme Switcher** - Automatic dark/light theme switching
- **Panel Workspace Scroll** - Scroll on panel to switch workspaces
- **Advanced Alt+Tab Window Switcher** - Enhanced Alt+Tab experience

### 🎨 Visual Enhancement Extensions
- **Blur My Shell** - Blur effects for shell elements
- **AppIndicator** - System tray support
- **User Themes** - Custom theme support
- **Just Perfection** - Customize GNOME interface elements

### 📊 System Monitoring Extensions
- **TopHat** - Elegant system resource monitor in top bar
- **System Monitor Next** - Classic system monitor with graphs
- **Resource Monitor** - Real-time monitoring in top bar
- **Battery Health Charging** - Battery charge limiting for laptop health
- **Battery Time** - Show battery time remaining
- **Quick Settings Audio Panel** - Enhanced audio controls

### 🔧 Managing Extensions

Use these tools to manage your extensions:
- **GNOME Tweaks** - Basic extension management
- **Extension Manager** - Advanced extension management
- **dconf Editor** - Low-level settings configuration

Extensions can be enabled/disabled through Extension Manager or GNOME Tweaks after installation.

## Note

This configuration prioritizes **stability over features** to ensure reliable laptop operation. The desktop configuration in `../default/` can use more aggressive settings since desktop hardware is typically more predictable.