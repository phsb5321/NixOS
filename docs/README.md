# NixOS Configuration Documentation

This directory contains comprehensive documentation for the NixOS configuration.

## Quick Start

For immediate setup and common tasks, see the main [README.md](../README.md) in the project root.

## Documentation Structure

### Desktop Environment

- [GNOME Theming Guide](gnome-theming.md) - Modern theming setup, accent colors, and management tools

### System Configuration

- [Wayland Improvements](wayland-improvements.md) - Wayland setup and troubleshooting
- [Modules Documentation](modules/) - Detailed module configuration guides
- [Troubleshooting](troubleshooting/) - Common issues and solutions

## Utility Scripts

The following management scripts are available in `/user-scripts/`:

### System Management

- `nixswitch.sh` - Enhanced NixOS rebuild script with parallel processing
- `nixswitch` - Simple alias wrapper for nixswitch.sh
- `nix-shell-selector.sh` - Interactive development environment selector

### System Utilities

- `wayland-diagnostic.sh` - Comprehensive Wayland troubleshooting and diagnostics
- `textractor.sh` - Text extraction and processing utility

## Getting Help

Each script includes built-in help accessible with the `--help` or `-h` flag:

```bash
./script-name.sh --help
```

## Configuration Layout

```text
NixOS/
├── docs/                    # Documentation (this directory)
├── hosts/                   # Host-specific configurations
│   ├── default/            # Desktop configuration
│   └── laptop/             # Laptop configuration
├── modules/                 # Reusable NixOS modules
│   ├── core/               # Core system modules
│   ├── desktop/            # Desktop environment modules
│   ├── home/               # Home Manager modules
│   ├── networking/         # Network configuration
│   └── packages/           # Package collections
├── shells/                  # Development shell environments
├── user-scripts/           # System management scripts
├── flake.nix              # Main flake configuration
└── README.md              # Main project documentation
```

## Features

### Multi-Host Support

- **Desktop**: AMD-based desktop with GNOME
- **Laptop**: Intel-based laptop with optimized power management

### Modern Technology Stack

- **NixOS 25.05**: Latest stable release
- **Wayland**: Full Wayland support with fallback
- **GNOME**: Modern desktop environment with theming
- **Home Manager**: Declarative user configuration

### Development Environment

- **Multiple Language Support**: Nix shells for various programming languages
- **Interactive Shell Selector**: Easy development environment switching
- **Enhanced Rebuild Script**: Parallel processing and optimizations

## Contributing

When adding new features or making changes:

1. Update relevant documentation in this directory
2. Test scripts and configurations thoroughly
3. Follow existing code organization patterns
4. Update this index if adding new documentation files
