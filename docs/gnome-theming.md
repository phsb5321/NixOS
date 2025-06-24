# GNOME Theming Guide

## Overview

This guide covers the comprehensive GNOME theming improvements and management tools available in this NixOS configuration.

## Modern Theme Stack

The configuration includes a modern, cohesive theming setup:

- **GTK Theme**: `Orchis-Dark-Compact` - Modern dark theme with elegant rounded corners
- **Icon Theme**: `Tela-dark` - Contemporary, colorful, consistent icon design
- **Cursor Theme**: `Bibata-Modern-Classic` - Smooth, animated cursors
- **Extensions**: Enhanced visual effects and modern polish

## Quick Setup

### 1. Apply Theme Configuration

```bash
sudo nixos-rebuild switch
```

### 2. Refresh GNOME Shell

Press `Alt + F2`, type `r`, press `Enter` to restart GNOME Shell and apply the modern theme.

## Features

### Visual Enhancements

- Rounded window corners
- Enhanced transparency and blur effects
- Smooth window animations
- Optimized dash-to-dock appearance
- Professional color schemes
- Modern typography

### Extensions Included

- **User Themes**: Custom shell theme support
- **Dash to Dock**: Enhanced dock with transparency
- **Blur My Shell**: Modern blur effects
- **Just Perfection**: Panel and animation optimization
- **Rounded Window Corners**: Modern window aesthetics
- **Compiz Windows Effect**: Subtle window animations

### Configuration

- Centralized theme management
- Persistent settings across sessions
- Easy customization and reset options
- NixOS declarative configuration

## Troubleshooting

### Theme Not Applied

1. Rebuild system: `sudo nixos-rebuild switch`
2. Restart GNOME Shell: `Alt+F2` → `r` → `Enter`
3. Log out and back in if needed

### Extensions Not Working

1. Enable extensions in GNOME Extensions app
2. Check extension compatibility
3. Restart GNOME Shell

## Configuration Files

The theming configuration is managed in:

- `/modules/desktop/gnome/default.nix` - Main GNOME theming setup
- `/modules/desktop/options.nix` - Theming options and accent colors
