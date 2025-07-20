# VS Code Bleeding Edge & Enhanced nixswitch Documentation

## Overview

Your NixOS configuration has been enhanced to provide bleeding edge VS Code packages and an improved nixswitch script with comprehensive flake update capabilities.

## Changes Made

### 1. Bleeding Edge VS Code Configuration

**File Modified:** `modules/packages/default.nix`

- **Changed VS Code source:** Now uses `pkgs-master.vscode` instead of stable packages
- **Added nixpkgs-master input:** New bleeding edge package source from NixOS master branch
- **Enhanced package references:** Added support for `pkgs-master` parameter

### 2. Enhanced Flake Configuration  

**File Modified:** `flake.nix`

- **Added nixpkgs-master input:** `github:nixos/nixpkgs/master` for absolute latest packages
- **New bleeding edge hosts:** Added `default-bleeding` and `laptop-bleeding` configurations
- **Enhanced package sets:** Added `pkgs-master` and updated `bleedPkgs` to use master branch
- **Flexible host configurations:** Easy switching between stable and bleeding edge

### 3. Improved nixswitch Script

**File Modified:** `user-scripts/nixswitch`

- **Version updated:** Now v7.1.0 with bleeding edge support
- **Enhanced flake updates:** Added registry pinning and `--refresh` flag
- **Channel updates:** New `update_nix_channels()` function
- **Bleeding edge support:** `--bleeding-edge` flag and auto-detection
- **Better update process:** Enhanced parallel updates with registry refresh

### 4. New Scripts and Tools

**New Files Created:**

1. **`user-scripts/nixswitch-bleeding`** - Convenience script for bleeding edge updates
2. **`user-scripts/enable-bleeding-edge.sh`** - Script to enable bleeding edge packages per host
3. **`modules/core/bleeding-edge.nix`** - Module for global bleeding edge package management (currently disabled)

## Usage Instructions

### Basic Usage

```bash
# Regular rebuild with enhanced flake updates
./nixswitch

# Use bleeding edge packages
./nixswitch --bleeding-edge

# Or use the convenience script
./nixswitch-bleeding

# Specify bleeding edge host configurations
./nixswitch default-bleeding
./nixswitch laptop-bleeding
```

### Available Options

```bash
nixswitch [OPTIONS] [HOST]

Options:
  --help/-h                Show help
  --non-interactive/-y     Skip confirmations  
  --bleeding-edge/-b       Use bleeding edge packages (master branch)
  --commit-message MSG     Custom commit message

Host Configurations:
  default                  Standard desktop configuration
  laptop                   Standard laptop configuration
  default-bleeding         Bleeding edge desktop configuration
  laptop-bleeding          Bleeding edge laptop configuration
```

### What Gets Updated

The enhanced nixswitch now updates:

1. **Git repository** - Fetches latest changes from origin
2. **Nix registry** - Pins nixpkgs to latest unstable 
3. **Flake inputs** - Updates all flake dependencies with `--refresh`
4. **Nix channels** - Updates user channels if they exist
5. **System configuration** - Builds and switches to new generation

## Bleeding Edge Features

### VS Code
- **Source:** NixOS master branch (absolute latest)
- **Update frequency:** Daily (when you run nixswitch)
- **Extensions:** Managed separately through VS Code

### Package Sources
- **Stable:** `nixpkgs` (NixOS 25.05 LTS)
- **Unstable:** `nixpkgs-unstable` (tested rolling)  
- **Bleeding:** `nixpkgs-master` (absolute latest)

### Host Configurations
- **Standard hosts:** Use stable nixpkgs by default
- **Bleeding hosts:** Use master branch for maximum freshness
- **Easy switching:** Change between configurations anytime

## Performance & Safety

### Enhanced Updates
- **Parallel processing:** Git, flake, and validation run simultaneously
- **Better error handling:** Clear feedback on failures
- **Registry management:** Keeps Nix registry in sync
- **Disk space monitoring:** Warns about low space

### Safety Features
- **Syntax validation:** Checks configuration before building
- **Host validation:** Ensures target configuration exists
- **Rollback capability:** NixOS generations allow easy rollback
- **Non-destructive:** Original configurations remain available

## Troubleshooting

### If VS Code Seems Outdated
```bash
# Force flake update and rebuild
./nixswitch --bleeding-edge

# Check current VS Code version
code --version
```

### If Build Fails
```bash
# Check configuration syntax
nix flake check

# View detailed errors
nixos-rebuild build --flake .#default --show-trace
```

### Switch Back to Stable
```bash
# Use regular host configuration
./nixswitch default

# Or rollback to previous generation
sudo nixos-rebuild --rollback
```

## Files Modified Summary

- ✅ `flake.nix` - Added nixpkgs-master input and bleeding edge hosts
- ✅ `modules/packages/default.nix` - Updated VS Code to use bleeding edge
- ✅ `user-scripts/nixswitch` - Enhanced with bleeding edge support and better updates
- ✅ `modules/core/default.nix` - Added bleeding edge module import (disabled)
- ✅ Created new helper scripts and modules

Your NixOS system now has cutting-edge VS Code with comprehensive update management!
