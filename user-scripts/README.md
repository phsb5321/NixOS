# User Scripts

This directory contains essential utility scripts for managing your NixOS system and development environment.

## System Management

- **`nixswitch.sh`** - Enhanced NixOS rebuild script with parallel processing and optimization
- **`nixswitch`** - Simple alias wrapper for nixswitch.sh
- **`nix-shell-selector.sh`** - Interactive development environment selector

## System Utilities

- **`wayland-diagnostic.sh`** - Comprehensive Wayland troubleshooting and diagnostic tools
- **`textractor.sh`** - Text extraction and processing utility

## Usage

Each script includes built-in help:

```bash
./script-name.sh --help
```

## Quick Start

```bash
# Rebuild NixOS configuration
./nixswitch.sh default

# Select and enter a development shell
./nix-shell-selector.sh

# Extract text from project files
./textractor.sh /path/to/project output.txt

# Diagnose Wayland issues
./wayland-diagnostic.sh
```

## Documentation

- See [README-nixswitch.md](README-nixswitch.md) for detailed information about the enhanced rebuild script
- See [../docs/](../docs/) for complete system documentation
