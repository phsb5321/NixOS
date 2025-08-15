# GNOME Integration Improvements for NixOS Default Host

## Overview

This document outlines the comprehensive improvements made to the GNOME desktop environment integration for the default host in this NixOS configuration. These changes modernize the GNOME setup, improve performance, and provide a better user experience.

## Major Improvements Implemented

### 1. Modern NixOS 25.11 Compatibility ✅

**Previous Issues:**
- Using deprecated `services.xserver.displayManager.gdm.enable` syntax
- Outdated GNOME service configurations
- Mixed X11/Wayland configuration causing conflicts

**Improvements:**
- Updated to modern `services.displayManager.gdm.enable` syntax
- Proper Wayland-first configuration with X11 fallback
- Updated deprecated service names:
  - `services.gnome.tracker.enable` → `services.gnome.tinysparql.enable`
  - `services.gnome.tracker-miners.enable` → `services.gnome.localsearch.enable`

### 2. Enhanced Display Server Configuration ✅

**Previous State:**
- Forced X11 mode for "AMD GPU stability"
- Complex X11 configuration for all scenarios

**Improvements:**
- **Wayland by default** when hardware acceleration is enabled
- Simplified X11 configuration only for software rendering fallback
- Proper environment variables for Wayland optimization:
  ```nix
  "MOZ_ENABLE_WAYLAND" = "1";
  "QT_QPA_PLATFORM" = "wayland;xcb";
  "SDL_VIDEODRIVER" = "wayland";
  "CLUTTER_BACKEND" = "wayland";
  "GDK_BACKEND" = "wayland,x11";
  "NIXOS_OZONE_WL" = "1"; # Electron apps Wayland support
  ```

### 3. Experimental Features for Better UX ✅

**New Features Enabled:**
- `scale-monitor-framebuffer` - Fractional scaling support (125%, 150%, 175%)
- `variable-refresh-rate` - VRR support for compatible displays
- `xwayland-native-scaling` - Crisp HiDPI scaling for X11 apps

### 4. Optimized Extension Management ✅

**Previous Issues:**
- Extension configuration duplicated between shared and host configs
- Inconsistent extension enabling mechanism

**Improvements:**
- Centralized extension configuration in host-specific files
- Reduced duplication in shared configuration
- Proper dconf-based extension configuration with specific settings:
  ```nix
  "org/gnome/shell/extensions/dash-to-dock" = {
    dock-position = "BOTTOM";
    autohide = true;
    intellihide = true;
  };
  ```

### 5. Comprehensive Theme Integration ✅

**New Theming Features:**
- **Dark theme by default** with proper color scheme configuration
- **Qt integration** with GNOME Adwaita theme
- **Font configuration** with Cantarell and Source Code Pro
- **Proper cursor theming** with Adwaita cursors
- **Icon theme consistency** across all applications

### 6. Hardware Integration Improvements ✅

**Enhanced Hardware Support:**
- Automatic screen rotation with `hardware.sensor.iio.enable`
- Improved AMD GPU optimization with proper Wayland support
- System tray support with AppIndicator extension
- Enhanced printer discovery and support

### 7. Service Configuration Optimization ✅

**Service Improvements:**
- **Proper power management** with `power-profiles-daemon` (disabled conflicting services)
- **File indexing and search** with updated TinySparql/LocalSearch services
- **Security improvements** by disabling unnecessary sharing services
- **Bluetooth and audio integration** properly configured

### 8. Development and Validation Tools ✅

**New Tools Added:**
- Comprehensive GNOME validation script (`scripts/validate-gnome.sh`)
- Proper error handling and diagnostics
- Build validation ensuring configuration works correctly

## Configuration Structure

### Host-Specific Configuration (`hosts/default/configuration.nix`)
- Hardware-specific GNOME settings
- GPU optimization based on active variant
- Extension configuration and theming
- Display server and experimental features

### Shared Configuration (`hosts/shared/common.nix`)
- Base GNOME services and applications
- Common extensions available to all hosts
- Shared keyboard and input configuration
- Base system integration

## Key Technical Decisions

### 1. Wayland-First Approach
- **Rationale:** Better performance, security, and modern features
- **Implementation:** Automatic Wayland when hardware acceleration available
- **Fallback:** X11 for software rendering scenarios

### 2. Power Management Strategy
- **Choice:** `power-profiles-daemon` over TLP/thermald
- **Reason:** Better GNOME integration and user control
- **Benefit:** Simplified power management with GUI controls

### 3. Extension Philosophy
- **Approach:** Curated set of essential extensions
- **Focus:** Productivity and system monitoring
- **Maintenance:** Host-specific configuration for customization

### 4. Theme Consistency
- **Goal:** Unified dark theme across all applications
- **Implementation:** Proper Qt/GTK theme integration
- **Result:** Consistent visual experience

## Performance Optimizations

### AMD GPU Specific
- Proper RADV driver configuration
- Hardware acceleration for Wayland
- Optimized power management
- Variable refresh rate support

### Memory and CPU
- TinySparql for efficient file indexing
- Disabled unnecessary background services
- Optimized animation settings based on hardware capability

## User Experience Improvements

### Navigation
- Dash-to-Dock with intelligent hiding
- Workspace indicators and scrolling
- Enhanced Alt+Tab functionality

### Productivity
- System monitoring with Vitals extension
- Clipboard management
- Phone integration with GSConnect
- Blur effects for modern aesthetics

### Accessibility
- Proper font rendering and sizing
- Cursor theme consistency
- Keyboard shortcut optimization
- High contrast support ready

## Validation and Testing

The configuration includes a comprehensive validation script that checks:

- ✅ GNOME session detection
- ✅ Display server verification (Wayland/X11)
- ✅ Service status monitoring
- ✅ Extension functionality
- ✅ Hardware acceleration status
- ✅ Audio system integration
- ✅ Font availability
- ✅ Qt theme integration
- ✅ Essential application presence

## Migration Notes

### From Previous Configuration
1. **Wayland transition:** Users will automatically switch to Wayland on next login
2. **Extension changes:** Some extensions may need re-enabling after update
3. **Theme application:** Dark theme will be applied system-wide
4. **Service updates:** File indexing will be re-initialized with new services

### Rollback Capability
- Configuration maintains X11 fallback for compatibility
- Software rendering mode available for troubleshooting
- Modular design allows selective feature disabling

## Future Considerations

### Potential Enhancements
- GNOME 46+ features integration
- Additional gaming optimizations
- Enhanced multi-monitor support
- Custom GTK4 theming

### Maintenance Tasks
- Regular extension compatibility checks
- Performance monitoring and optimization
- Security hardening as needed
- User feedback integration

## Troubleshooting

### Common Issues and Solutions

**Issue:** Black screen or login loop
**Solution:** Switch to software rendering variant by changing `activeVariant` to `variants.software`

**Issue:** Extensions not loading
**Solution:** Run `gnome-extensions reset` and re-enable through GUI

**Issue:** Qt applications don't match theme
**Solution:** Verify `QT_QPA_PLATFORMTHEME=gnome` environment variable

**Issue:** Poor performance
**Solution:** Check hardware acceleration with validation script

### Diagnostic Commands
```bash
# Run comprehensive validation
./scripts/validate-gnome.sh

# Check GNOME session status
loginctl show-session $(loginctl | grep $(whoami) | awk '{print $1}')

# Verify display server
echo $XDG_SESSION_TYPE

# Check GPU status
glxinfo | grep "OpenGL renderer"
```

## Conclusion

These improvements provide a modern, performant, and user-friendly GNOME desktop environment that takes full advantage of NixOS's declarative configuration model. The setup is optimized for AMD hardware while maintaining compatibility with various scenarios through the variant system.

The configuration is now future-proof, maintainable, and provides an excellent foundation for a productive desktop workstation.
