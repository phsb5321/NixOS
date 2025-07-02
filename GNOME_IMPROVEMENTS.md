# Comprehensive Gnome Configuration Enhancement

## Overview

This document outlines the extensive improvements made to the Gnome desktop environment configuration, featuring comprehensive extension support, advanced system monitoring, unified theming with dark mode support, enhanced VSCode integration, and cursor consistency fixes.

## Major Changes Made

### 1. Extensive Gnome Extensions Collection (`modules/desktop/gnome/default.nix`)

#### System Monitoring Extensions - Multiple Options

- **Vitals** - Complete system monitoring with temperature, voltage, fan speed, memory, CPU, network, and storage stats
- **System Monitor Next** - Classic system monitor with real-time graphs
- **TopHat** - Elegant system resource monitor for the top bar
- **Multicore System Monitor** - Individual CPU core monitoring
- **System Monitor 2** - Alternative comprehensive system monitor
- **Resource Monitor** - Real-time monitoring directly in the top bar

#### Productivity & Customization Extensions

- **User Themes** - Custom theme support with automatic dark/light switching
- **Caffeine** - Prevent screen lock during presentations or media
- **AppIndicator** - System tray support for legacy applications
- **Blur My Shell** - Beautiful blur effects for shell elements
- **Clipboard Indicator** - Advanced clipboard manager with history
- **Clipboard History** - Enhanced clipboard management
- **Night Theme Switcher** - Automatic dark/light theme switching based on time
- **GSConnect** - Phone integration (KDE Connect protocol)

#### Workspace & Window Management

- **Workspace Indicator** - Better workspace display and switching
- **Advanced Alt+Tab Window Switcher** - Enhanced window switching with search
- **Smart Auto Move** - Automatically remember and restore window positions
- **Current Workspace Name** - Display workspace names in the panel
- **Improved Workspace Indicator** - Enhanced workspace visualization
- **Panel Workspace Scroll** - Switch workspaces by scrolling on the panel

#### Quick Access & Navigation

- **Places Status Indicator** - Quick access to bookmarks and favorite locations
- **Removable Drive Menu** - Easy USB drive and external storage management
- **Sound Output Device Chooser** - Quick audio device switching
- **Weather or Not** - Weather information in the top panel

#### Visual Enhancements

- **Logo Menu** - Custom logo in the activities overview
- **Desktop Icons NG** - Desktop icons support for modern Gnome
- **Just Perfection** - Fine-tune Gnome shell behavior and appearance

#### Additional Utilities

- **Translate Clipboard** - Translate clipboard content on demand
- **Night Light Slider** - Manual control of night light temperature

### 2. Complete Dark Theme Support

#### Automatic Theme Switching

- **Night Theme Switcher** extension automatically changes themes based on:
  - System night light settings
  - Time of day
  - Manual override options

#### Theme Configuration

- **GTK Themes**: Adwaita / Adwaita-dark with automatic switching
- **Shell Themes**: Coordinated with GTK themes for consistency
- **Icon Themes**: Adwaita icons optimized for both light and dark modes
- **Application Integration**: All applications respect system theme preference

#### VSCode Theme Integration

- **Adwaita Theme Extension**: Native Gnome look and feel
- **Automatic Color Scheme**: Follows system dark/light preference
- **Custom Title Bar**: Integrates with Gnome window management
- **Command Center**: Modern VSCode UI matching Gnome design

### 3. Unified Cursor Theme System

#### System-wide Cursor Consistency

- **GDM Configuration**: Login screen uses Adwaita cursor (size 24)
- **User Session**: Unified Adwaita cursor across all applications
- **Environment Variables**: System-wide cursor theme enforcement
- **Multi-Environment Support**: Consistent cursor in X11, Wayland, and mixed sessions

#### Technical Implementation

```nix
# GDM cursor configuration
programs.dconf.profiles.gdm.databases = [{
  settings."org/gnome/desktop/interface" = {
    cursor-theme = "Adwaita";
    cursor-size = mkInt32 24;
  };
}];

# User session cursor
home.pointerCursor = {
  name = "Adwaita";
  size = 24;
  package = pkgs.adwaita-icon-theme;
};
```

### 4. Enhanced VSCode Configuration (`modules/home/programs/vscode.nix`)

#### Gnome Integration Features

- **Adwaita Theme Extension**: Native Gnome appearance
- **Window Integration**: Custom title bar with command center
- **Auto Color Scheme**: Follows system dark/light preference
- **Proper Font Configuration**: JetBrains Mono Nerd Font integration

#### Development Environment

- **Nix Language Support**: Full nixd language server integration
- **Git Integration**: GitLens and native Git tools
- **Multi-language Support**: Python, Rust, Go, C++, JavaScript/TypeScript
- **Productivity Extensions**: Auto-rename tag, path intellisense, error lens
- **Code Quality**: Spell checker, prettier formatting, linting

#### Editor Optimizations

```json
{
  "workbench.colorTheme": "Adwaita Dark/Light (auto)",
  "workbench.iconTheme": "adwaita",
  "window.titleBarStyle": "custom",
  "window.commandCenter": true,
  "editor.renderLineHighlight": "none"
}
```

### 5. System Monitoring in Status Bar

#### Multiple Monitoring Options

Users can choose from several system monitoring extensions:

1. **Vitals** (Recommended)

   - CPU usage, temperature, and load
   - Memory and swap usage
   - Network upload/download speeds
   - Storage statistics
   - Fan speeds and voltages
   - Configurable sensor selection

2. **System Monitor Next**

   - Classic graphs and charts
   - Historical data tracking
   - Customizable display options

3. **TopHat**

   - Clean, elegant design
   - Minimal resource usage
   - Essential metrics only

4. **Resource Monitor**
   - Real-time CPU, GPU, RAM monitoring
   - Disk and network statistics
   - Temperature sensors

### 6. Comprehensive Extension Configuration

#### Pre-configured Extension Settings

All extensions come with optimized default configurations:

- **Dash to Dock**: Bottom position, auto-hide, dynamic transparency
- **Vitals**: Shows CPU, memory, load, temperature, and network in panel
- **Blur My Shell**: Subtle blur effects with optimal performance
- **Caffeine**: Smart activation for fullscreen content
- **Night Theme Switcher**: Coordinated with system night light
- **GSConnect**: Full phone integration with notifications and file sharing

#### Productivity Enhancements

- **Workspace Management**: Enhanced workspace switching and indication
- **Window Control**: Smart window positioning and Alt+Tab improvements
- **Quick Access**: Streamlined access to drives, bookmarks, and settings
- **Clipboard Management**: Advanced clipboard history and management

### 7. Performance Optimizations

#### Graphics and Rendering

- **GSK_RENDERER**: OpenGL optimization for NixOS 25.05
- **Wayland/X11 Support**: Adaptive backend selection
- **Hardware Acceleration**: Proper GPU utilization

#### Extension Performance

- **Asynchronous Updates**: Non-blocking system monitoring
- **Efficient Polling**: Optimized sensor reading intervals
- **Memory Management**: Proper cleanup and resource management

## Installation and Usage

### Applying the Configuration

```bash
sudo nixos-rebuild switch
```

### Extension Management

- Extensions are automatically installed and configured
- Use **Extension Manager** (`gnome-extension-manager`) for fine-tuning
- All extensions have sensible defaults but are fully customizable

### Dark Theme Usage

- Dark theme automatically activates based on night light settings
- Manual override available in Settings > Appearance
- VSCode follows system theme automatically
- All applications respect the system theme preference

### System Monitoring

- **Vitals** shows in the top bar by default
- Click indicators for detailed system information
- Configure visible sensors in extension preferences
- Multiple monitoring extensions can run simultaneously

## Troubleshooting

### Extension Issues

```bash
# Restart GNOME Shell (X11)
Alt + F2, type 'r', press Enter

# Restart GNOME Shell (Wayland)
sudo systemctl restart gdm
```

### Theme Problems

```bash
# Reset GNOME settings
dconf reset -f /org/gnome/

# Reload user configuration
home-manager switch
```

### VSCode Integration

- Ensure Adwaita theme extension is installed
- Check that auto-detect color scheme is enabled
- Verify font configuration in settings

## Benefits

### Enhanced User Experience

- **Unified Design Language**: Consistent Adwaita theming throughout
- **Comprehensive Monitoring**: Multiple system monitoring options
- **Smart Automation**: Automatic theme switching and power management
- **Productivity Tools**: Advanced clipboard, workspace, and window management

### Developer Experience

- **Integrated Development**: VSCode with Gnome theming and Nix support
- **System Awareness**: Real-time system monitoring during development
- **Seamless Workflow**: Unified keyboard shortcuts and window management

### System Administration

- **Resource Monitoring**: Real-time system performance tracking
- **Hardware Management**: Temperature, fan, and power monitoring
- **Storage Management**: Disk usage and removable drive handling
- **Network Monitoring**: Real-time network activity tracking

This configuration transforms GNOME into a comprehensive, visually cohesive, and highly functional desktop environment optimized for both productivity and system monitoring.
